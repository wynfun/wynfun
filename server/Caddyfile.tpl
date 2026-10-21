# Web server config. __DOMAIN__ and __HASH__ are filled in by setup.sh
www.__DOMAIN__ {
	redir https://__DOMAIN__{uri} permanent
}

__DOMAIN__ {
	root * /srv/wynfun/live
	encode zstd gzip
	file_server
	header {
		X-Content-Type-Options nosniff
		Referrer-Policy strict-origin-when-cross-origin
		X-Frame-Options SAMEORIGIN
		Strict-Transport-Security "max-age=31536000"
		-Server
	}
	header Cache-Control "no-cache"
	@static path /img/* /data/*
	header @static Cache-Control "public, max-age=3600, stale-while-revalidate=86400"
	log {
		output file /var/log/caddy/live.log {
			roll_size 20MiB
			roll_keep 5
		}
	}
}

staging.__DOMAIN__ {
	root * /srv/wynfun/staging
	encode zstd gzip
	basic_auth {
		staging __HASH__
	}
	file_server
	header {
		X-Robots-Tag "noindex, nofollow"
		Cache-Control "no-store"
		-Server
	}
}
