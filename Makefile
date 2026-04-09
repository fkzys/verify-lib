PREFIX  = /usr
DESTDIR =

CC     ?= cc
CFLAGS ?= -O2 -Wall -Wextra -Werror

.PHONY: build install uninstall clean

build:
	$(CC) $(CFLAGS) -o verify-lib verify-lib.c

install:
	install -Dm755 verify-lib $(DESTDIR)$(PREFIX)/bin/verify-lib
	install -Dm644 LICENSE $(DESTDIR)$(PREFIX)/share/licenses/verify-lib/LICENSE

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/verify-lib
	rm -rf $(DESTDIR)$(PREFIX)/share/licenses/verify-lib/

clean:
	rm -f verify-lib
