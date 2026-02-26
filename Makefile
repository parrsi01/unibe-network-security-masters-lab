PYTHON ?= python3

.PHONY: help validate validate-quick test pycheck lint sample-triage tree

help:
	@printf "Targets:\n"
	@printf "  make validate        Run full repository validation\n"
	@printf "  make validate-quick  Run quick repository validation\n"
	@printf "  make test            Run unit tests\n"
	@printf "  make pycheck         Python syntax checks\n"
	@printf "  make lint            Shell + Python syntax checks\n"
	@printf "  make sample-triage   Analyze bundled Suricata EVE sample\n"
	@printf "  make tree            Print repository tree (fallback if tree missing)\n"

validate:
	./validate_repo.sh

validate-quick:
	./validate_repo.sh --quick

test:
	$(PYTHON) -m unittest discover -s tests -p 'test_*.py' -v

pycheck:
	$(PYTHON) -m py_compile scripts/analyze_suricata_eve_sample.py tests/test_suricata_triage.py

lint:
	bash -n validate_repo.sh
	find scripts labs -type f -name '*.sh' -exec bash -n {} \;
	$(MAKE) pycheck

sample-triage:
	$(PYTHON) scripts/analyze_suricata_eve_sample.py datasets/suricata/eve_sample.jsonl

tree:
	@if command -v tree >/dev/null 2>&1; then tree -a -I '.git|venv|.venv'; else find . -path './.git' -prune -o -print | sort; fi

