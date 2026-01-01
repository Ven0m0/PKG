.PHONY: all format lint check format-python format-shell clean help update-packages publish

# Default target
all: format lint

# Help target
help:
	@echo "PKG Repository Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make format          - Format all code"
	@echo "  make lint            - Lint all code"
	@echo "  make check           - Format and lint (same as 'make')"
	@echo "  make clean           - Remove build artifacts"
	@echo "  make update-packages - Update packages.json"
	@echo "  make publish         - Update, commit and push"
	@echo "  make help            - Show this help"

# Combined check
check: format lint

# Format everything
format: format-python format-shell
	@echo "✓ Formatting complete"

# Lint everything
lint: lint-shell lint-packages
	@echo "✓ Linting complete"

# Python formatting
format-python:
	@echo "→ Formatting Python..."
	@if command -v ruff >/dev/null 2>&1; then \
		ruff format vp-dev --quiet; \
	else \
		echo "  ⚠ ruff not found, skipping Python formatting"; \
	fi

# Shell script formatting
format-shell:
	@echo "→ Formatting shell scripts..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -w -i 2 -bn -ci vp setup.sh; \
		find . -maxdepth 2 -type f -name "PKGBUILD" -exec shfmt -w -i 2 -bn -ci {} \; 2>/dev/null || true; \
	else \
		echo "  ⚠ shfmt not found, skipping shell formatting"; \
	fi

# Shell script linting
lint-shell:
	@echo "→ Linting shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck vp setup.sh || true; \
	else \
		echo "  ⚠ shellcheck not found, skipping shell linting"; \
	fi

# Package linting
lint-packages:
	@echo "→ Linting packages with namcap..."
	@if command -v namcap >/dev/null 2>&1; then \
		find . -maxdepth 2 -type f -name "PKGBUILD" -exec namcap {} \; 2>/dev/null || true; \
	else \
		echo "  ⚠ namcap not found, skipping package linting"; \
	fi

# Update packages.json
update-packages:
	@echo "→ Updating packages.json..."
	@if [ -f vp-dev ]; then \
		./vp-dev update; \
	else \
		echo "  ✗ vp-dev not found"; \
		exit 1; \
	fi

# Publish
publish:
	@echo "→ Publishing repository..."
	@if [ -f vp-dev ]; then \
		./vp-dev publish; \
	else \
		echo "  ✗ vp-dev not found"; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	@echo "→ Cleaning build artifacts..."
	@find . -maxdepth 2 \( -name "*.pkg.tar.zst" -o -name "*.pkg.tar.xz" -o -name "*.log" -o -name "*.bak" \) -delete
	@find . -maxdepth 2 -type d \( -name "pkg" -o -name "src" \) -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Cleaned"
