# Web server config. __DOMAIN__ and __HASH__ are filled in by setup.sh
www.__DOMAIN__ {
	redir https://__DOMAIN__{uri} permanent
}

__DOMAIN__ {
	encode zstd gzip
	header {
		X-Content-Type-Options nosniff
		Referrer-Policy strict-origin-when-cross-origin
		X-Frame-Options SAMEORIGIN
		Strict-Transport-Security "max-age=31536000"
		-Server
	}
	log {
		output file /var/log/caddy/live.log {
			roll_size 20MiB
			roll_keep 5
		}
	}
	handle /api/* {
		reverse_proxy 127.0.0.1:8081
	}
	handle {
		root * /srv/wynfun/live
		file_server
		header Cache-Control "no-cache"
		@static path /img/* /data/*
		header @static Cache-Control "public, max-age=3600, stale-while-revalidate=86400"
	}
}

staging.__DOMAIN__ {
	encode zstd gzip
	header {
		X-Robots-Tag "noindex, nofollow"
		Cache-Control "no-store"
		-Server
	}
	handle /api/* {
		basic_auth {
			staging __HASH__
		}
		reverse_proxy 127.0.0.1:8082
	}
	handle {
		basic_auth {
			staging __HASH__
		}
		root * /srv/wynfun/staging
		file_server
	}
}
