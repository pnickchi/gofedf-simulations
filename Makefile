.PHONY: all normal gamma lm-normal reports clean clean-normal clean-gamma clean-lm-normal clean-reports

all: normal gamma lm-normal reports
	@echo "All simulation steps completed."

normal:
	@echo "Starting IID Normal simulation..."
	@mkdir -p results/normal
	Rscript scripts/normal.R
	@echo "Finished IID Normal simulation."

gamma:
	@echo "Starting IID Gamma simulation..."
	@mkdir -p results/gamma
	Rscript scripts/gamma.R
	@echo "Finished IID Gamma simulation."

lm-normal:
	@echo "Starting LM Normal simulation..."
	@mkdir -p results/lm_normal
	Rscript scripts/lm_normal.R
	@echo "Finished LM Normal simulation."

glm-gamma:
	@echo "Starting GLM Gamma simulation..."
	@mkdir -p results/glm_gamma
	Rscript scripts/glm_gamma.R
	@echo "Finished GLM Gamma simulation."

reports:
	@echo "Rendering Quarto reports..."
	quarto render
	@echo "Finished rendering reports."

clean:
	@echo "Removing all simulation results and rendered reports..."
	rm -rf results/normal/*.rds
	rm -rf results/gamma/*.rds
	rm -rf results/lm_normal/*.rds
	rm -rf docs
	@echo "Clean complete."

clean-normal:
	@echo "Removing IID Normal simulation results..."
	rm -rf results/normal/*.rds
	@echo "IID Normal clean complete."

clean-gamma:
	@echo "Removing IID Gamma simulation results..."
	rm -rf results/gamma/*.rds
	@echo "IID Gamma clean complete."

clean-lm-normal:
	@echo "Removing LM Normal simulation results..."
	rm -rf results/lm_normal/*.rds
	@echo "LM Normal clean complete."

clean-reports:
	@echo "Removing rendered reports..."
	rm -rf docs
	@echo "Report clean complete."