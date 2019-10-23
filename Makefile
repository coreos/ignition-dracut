.PHONY: all
all:
	@echo "(No build step)"

.PHONY: install
install: all
	for x in dracut/*; do \
	  if ! [ -d "${x}" ]; then continue; fi; \
	  bn=$$(basename $$x); \
	  install -D -t $(DESTDIR)/usr/lib/dracut/modules.d/$${bn} $$x/*; \
	done
	install -D -t $(DESTDIR)/usr/lib/systemd/system systemd/*
	install -D -t $(DESTDIR)/etc/grub.d grub/*
