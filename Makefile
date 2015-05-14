build:
	docker build -t plumlife/erlang_otp-arm:17.5-2_nacl-dialyzed

push:
	docker push plumlife/erlang_otp-arm:17.5-2_nacl-dialyzed
