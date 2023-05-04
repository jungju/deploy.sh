deploy:
	git push origin main
	./deploy.sh

deploy-all:
	git add .
	git commit -a -m 'update'
	git push origin main
	./deploy.sh