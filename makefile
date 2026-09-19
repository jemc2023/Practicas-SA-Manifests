.PHONY: push
.PHONY: mr

push:
	@git add . && git commit -m "test: P9" && git push origin HEAD
mr:
	@make push
	@cd ../ && gh pr create --base master --head $$(git rev-parse --abbrev-ref HEAD) --title "ci/cd: test P8" --body "PR automatizado desde Makefile"


