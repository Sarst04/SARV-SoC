OUT_DIR := out/rtl

.PHONY: rtl clean

rtl:
	@rm -rf $(OUT_DIR)
	@mkdir -p $(OUT_DIR)

	@cp -r rtl/* $(OUT_DIR)/
	@cp -r memory $(OUT_DIR)/

	@mkdir -p $(OUT_DIR)/ip

	@cp -r ip/ACLINT/rtl 	$(OUT_DIR)/ip/ACLINT/
	@cp -r ip/Cache/rtl  	$(OUT_DIR)/ip/Cache/
	@cp -r ip/GPIO/rtl   	$(OUT_DIR)/ip/GPIO/
	@cp -r ip/PLIC/rtl   	$(OUT_DIR)/ip/PLIC/
	@cp -r ip/SARV/rtl/core	$(OUT_DIR)/ip/SARV/
	@cp -r ip/UART/rtl   	$(OUT_DIR)/ip/UART/

	@echo "Extraction completed."

clean:
	@rm -rf out
	@echo "Clean complete."