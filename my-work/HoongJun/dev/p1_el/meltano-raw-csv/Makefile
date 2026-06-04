.PHONY: setup pull run pipeline clean

setup:
	mkdir -p data/raw
	bq mk -d --location=US sctp-team2-project2-elt:olin_bronze_dev_jun || true
	meltano install

pull:
	mkdir -p data/raw
	gsutil -m cp gs://m2_olin_raw/*.csv data/raw/

run:
	meltano run olin-pipeline

pipeline: pull run

clean:
	rm -rf data/raw .meltano output
