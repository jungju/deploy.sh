deploy:
	git push origin main
	./deploy.sh

deploy-all:
	git add .
	git commit -a -m 'update'
	git push origin main
	./deploy.sh

deploy-force:
	FORCE_DEPLOY=true ./deploy.sh

deploy-major:
	VERSION_TARGET=major ./deploy.sh

deploy-minor:
	VERSION_TARGET=minor ./deploy.sh

deploy-only-k8s:
	ONLY_DEPLOY=true ./deploy.sh