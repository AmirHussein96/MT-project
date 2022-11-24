

git clone https://github.com/pytorch/fairseq

cd fairseq
pip install --editable ./
# install the nessesary libs
pip install tensorflow && pip install tensorboardX
pip install tensorboardX
pip install subword-nmt
# train BPE

cat train.*|  subword-nmt learn-bpe -s 10000 -o train_code_files

tokenizer=/home/ahussein/toolkit/smt/mosesdecoder/scripts/tokenizer/tokenizer.perl
detokenizer=/home/ahussein/toolkit/smt/mosesdecoder/scripts/tokenizer/detokenizer.perl

subword-nmt apply-bpe -c data/train_code_files < data/train.ta | subword-nmt get-vocab > data/vocab.ta
subword-nmt apply-bpe -c data/train_code_files < data/train.en | subword-nmt get-vocab > data/vocab.en
# tokenize to BPE

subword-nmt apply-bpe -c data/train_code_files --vocabulary data/vocab.en --vocabulary-threshold 50 < data/train.en > data/train.BPE.en
subword-nmt apply-bpe -c data/train_code_files --vocabulary data/vocab.en --vocabulary-threshold 50 < data/dev.en > data/dev.BPE.en
subword-nmt apply-bpe -c data/train_code_files --vocabulary data/vocab.en --vocabulary-threshold 50 < data/test.en > data/test.BPE.en 

subword-nmt apply-bpe -c data/train_code_files --vocabulary data/vocab.ta --vocabulary-threshold 50 < data/train.ta > train.BPE.ta
subword-nmt apply-bpe -c data/train_code_files --vocabulary data/vocab.ta --vocabulary-threshold 50 < data/dev.ta > dev.BPE.ta
subword-nmt apply-bpe -c data/train_code_files --vocabulary data/vocab.ta --vocabulary-threshold 50 < data/test.ta > test.BPE.ta 

# binarize the data
#fairseq-preprocess --source-lang de --target-lang en \
--trainpref data/train.BPE --validpref data/valid.BPE \
 --testpref data/test.BPE --destdir data-bin/iwslt14.de-en --workers 20
 
fairseq-preprocess \
        --source-lang ta --target-lang en \
        --srcdict data/vocab.ta --tgtdict data/vocab.en \
        --trainpref data/train.BPE --validpref data/dev.BPE \
        --testpref data/test.BPE --destdir data-bin/iwslt22.ta-en  --thresholdtgt 0 --thresholdsrc 0 \
        --workers 20 || exit 1;
		
		
# train the model
CUDA_VISIBLE_DEVICES=1 \
fairseq-train data-bin/iwslt22.ta-en \
 --arch transformer_iwslt_de_en --share-decoder-input-output-embed \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0  \
     --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000  \
      --dropout 0.3 --weight-decay 0.0001   --criterion label_smoothed_cross_entropy \
       --label-smoothing 0.1   --max-tokens 4096 --tensorboard-logdir tensorboard
	   
# decode

decode_dir=results
set=valid
#CUDA_VISIBLE_DEVICES='/home/xma/local/bin/free-gpu'\
#fairseq-generate data-bin/iwslt22.ta-en --valid-subset $set --path checkpoints/checkpoint_best.pt --batch-size 128 --beam 10 --remove-bpe | tee 

for set in "test" "valid"; do
CUDA_VISIBLE_DEVICES='/home/xma/local/bin/free-gpu' \
fairseq-generate data-bin/iwslt22.ta-en --source-lang ta --target-lang en \
--gen-subset $set --path checkpoints/checkpoint_best.pt --batch-size 128 \
--beam 10 --remove-bpe | tee $decode_dir/decode.${set}.log 
done

# scoring

for set in "test" "valid"; do
	cat $decode_dir/decode.$set.log | grep ^H | cut -f3- | $detokenizer -q -no-escape > ${decode_dir}/${set}_hyp.txt
	cat $decode_dir/decode.$set.log | grep ^T | cut -f2- | $detokenizer -q -no-escape > ${decode_dir}/${set}_ref.txt
	sacrebleu ${decode_dir}/${set}_ref.txt -i ${decode_dir}/${set}_hyp.txt -m bleu -lc > ${decode_dir}/${set}_results.txt
done
