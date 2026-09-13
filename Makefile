PROJECT := SARV-SoC

OUT_DIR := out
RTL_OUT := $(OUT_DIR)/rtl

IP_DIRS := \
	ip/SARV/rtl/core \
	ip/Cache/rtl \
	ip/ACLINT/rtl \
	ip/PLIC/rtl \
	ip/UART/rtl \
	ip/GPIO/rtl

.PHONY: rtl

rtl:
	@echo "Extracting $(PROJECT) RTL..."

	@rm -rf $(RTL_OUT)
	@mkdir -p $(RTL_OUT)

	@echo "Copying SoC RTL..."
	@find rtl -maxdepth 1 -type f \
		\( -name "*.v" -o -name "*.sv" \) \
		-exec cp {} $(RTL_OUT)/ \;

	@echo "Copying memory RTL..."
	@mkdir -p $(RTL_OUT)/memory
	@find memory -type f \
		\( -name "*.v" -o -name "*.sv" \) \
		-exec cp {} $(RTL_OUT)/memory/ \;

	@echo "Copying IP RTL..."
	@for dir in $(IP_DIRS); do \
		name=$$(echo $$dir | cut -d/ -f2); \
		dest="$(RTL_OUT)/ip/$$name"; \
		mkdir -p "$$dest"; \
		find "$$dir" -type f \
			\( -name "*.v" -o -name "*.sv" \) \
			-exec cp --parents {} "$$dest" \; ; \
	done

	@echo ""
	@echo "RTL extraction complete."
	@echo "Output: $(RTL_OUT)"
	@echo "Files: $$(find $(RTL_OUT) -type f \( -name "*.v" -o -name "*.sv" \) | wc -l)"