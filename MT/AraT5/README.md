# Fine-tune AraT5 with Tunisian data
## Install
```
git clone https://github.com/AmirHussein96/MT-project
pip install transformers==4.5.1 nltk datasets regex scikit-learn sentencepiece protobuf==3.20.0 fairscale sacrebleu rouge_score
pip install sacremoses
```

## Transform original data to json
```
for split in "train" "dev" "test1"; do
    python make_pairs_to_json.py ${split}/text.tc.rm.ta ta ${split}/text.tc.en en tu2en.${split}
done
```

## Fine-tune
```
!python MT-project/MT/AraT5/run_trainier_seq2seq_huggingface.py \
        --learning_rate 6e-5 --warmup_steps 4000 \
        --adam_beta1 0.9 --adam_beta2 0.98 \
        --weight_decay 0.0001 \
        --max_target_length 128 --max_source_length 128 \
        --label_smoothing_factor 0.1 \
        --per_device_train_batch_size 16 --per_device_eval_batch_size 16 --gradient_accumulation_steps 2 \
        --model_name_or_path "UBC-NLP/AraT5-base" \
        --output_dir /path/to/output/dir --overwrite_output_dir \
        --cache_dir /path/to/cache \
        --max_steps 100000 \
        --train_file /path/to/train \
        --validation_file /path/to/dev \
        --task "translation" --source_lang "ta" --target_lang "en" --num_beams 10 \
        --load_best_model_at_end --metric_for_best_model "eval_bleu" --greater_is_better True \
        --evaluation_strategy steps --eval_steps 2000 \
        --logging_strategy steps  --logging_steps 200 \
        --save_total_limit 2 \
        --predict_with_generate \
        --do_train --do_eval
```

## Predict
```
# predict for test set
!python MT-project/MT/AraT5/run_trainier_seq2seq_huggingface.py \
    --model_name_or_path /path/to/checkpoint \
    --output_dir /path/to/output \
    --test_file /path/to/test \
    --task "translation" --source_lang "ta" --target_lang "en" --num_beams 10 \
    --val_max_target_length 128 \
    --predict_with_generate \
    --metric_for_best_model "eval_bleu" \
    --do_predict \
    --max_test_samples 10
```