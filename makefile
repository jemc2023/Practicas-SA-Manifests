.PHONY: push
.PHONY: mr

push:
	@git add . && git commit -m "cicd: test P8" && git push origin HEAD



