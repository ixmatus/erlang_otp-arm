.PHONY: build push

build:
	sudo docker build -t plumlife/erlang_otp-arm:17.5-6-2_smp-nacl-dialyzed .

push:
	sudo docker push plumlife/erlang_otp-arm:17.5-6-2_smp-nacl-dialyzed

bash:
	docker run --rm -i -t plumlife/erlang_otp-arm:17.5-6-2_smp-nacl-dialyzed bash
