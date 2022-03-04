PERL=/usr/bin/perl

# Ubicacion de las paginas de Tickets
HOMEADMDIR=/usr/local/apache-root/cyber
#HOMEADMDIR=/usr/local/apache-root/cyber

DATE=/bin/date +%d/%m/%Y

all:
	@echo
	$(PERL) -wc  index.html
	@echo
	$(PERL) -wc  historico.html
	@echo
	$(PERL) -wc  millicom
	@echo
	$(PERL) -wc  millicom.pl
	@echo
	$(PERL) -wc  arnet
	@echo
	$(PERL) -wc  arnet.pl
	@echo
	$(PERL) -wc  guest
	@echo
	$(PERL) -wc  guest.pl
	@echo
	$(PERL) -wc  reboot
	@echo

install:
	install -m 700 -D index.html $(HOMEADMDIR)/index.html
#	install -m 700 habilitar.pl $(HOMEADMDIR)/habilitar.pl
	install -m 700 historico.html $(HOMEADMDIR)/historico.html
#	install -m 700 historico.pl $(HOMEADMDIR)/historico.pl
	install -m 644 icons/* $(HOMEADMDIR)/../icons/
	install -m 700 millicom $(HOMEADMDIR)/millicom
	install -m 700 millicom.pl /root/scripts/millicom
	install -m 700 arnet $(HOMEADMDIR)/arnet
	install -m 700 arnet.pl /root/scripts/arnet
	install -m 700 guest $(HOMEADMDIR)/guest
	install -m 700 guest.pl /root/scripts/guest
	install -m 700 reboot $(HOMEADMDIR)/reboot
	install -m 700 cyberbill.conf /etc/cyberbill.conf
	@echo
#	echo "Archivo Log Cyberbill - `$(DATE)`" >$(HOMEADMDIR)/../logs/tarifacion.log

install-all: install
	install -m 700 rc.firewall /etc/rc.d/rc.firewall
	install -m 700 rc.firewall.blocked /etc/rc.d/rc.firewall.blocked
	install -m 700 rc.firewall.accept /etc/rc.d/rc.firewall.accept
	/etc/rc.d/rc.firewall
	@echo

clean:
	rm -f $(HOMEADMDIR)/../logs/tarifacion.log
