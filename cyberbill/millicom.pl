#!/usr/bin/perl

$contador = 0;
open (ESTACIONES_ANDANDO, "/sbin/ipchains -nL input |");
while (<ESTACIONES_ANDANDO>)
{
	chop;
	if ($_ =~ m/REDIRECT/)
	{
		@linea = split /\s+/, $_;
		$estaciones[$contador] = $linea[3];
		$contador++;
	}
}
close (ESTACIONES_ANDANDO);

$comando = "/etc/rc.d/rc.firewall.accept";
system ("$comando");

$comando = "/usr/sbin/adsl-stop 1>/dev/null 2>&1 &";
system ("$comando");

$comando = "/sbin/ifconfig ppp0 down 1>/dev/null 2>&1 &";
system ("$comando");

$comando = "/usr/bin/killall pppd 1>/dev/null 2>&1 &";
system ("$comando");

$comando = "/usr/bin/killall adsl 1>/dev/null 2>&1 &";
system ("$comando");

$comando = "cp -rp /etc/ppp/pap-secrets.millicom /etc/ppp/pap-secrets";
system ("$comando");

$comando = "cp -rp /etc/ppp/pppoe.conf.millicom /etc/ppp/pppoe.conf";
system ("$comando");

$comando = "/usr/sbin/adsl-start";
$resultado = system ("$comando");

die &guardar_estaciones(@estaciones) unless $resultado == 0;

#$comando = "/usr/sbin/adsl-start; /etc/rc.d/rc.firewall";
$comando = "/etc/rc.d/rc.firewall";
system ("$comando");
foreach $estaciones (@estaciones)
{
	$comando = "/sbin/ipchains -I input 91 -s $estaciones -d 0/0 80 -p tcp -j REDIRECT 3128";
	system ("$comando");
	$comando = "/sbin/ipchains -I input 92 -s $estaciones -d 0/0 -j ACCEPT";
	system ("$comando");
	$comando = "/sbin/ipchains -I output 40 -d $estaciones -s 0/0 -j ACCEPT";
	system ("$comando");
}

exit;

sub guardar_estaciones
{
	local @estaciones = @_;
	$archivo = "/tmp/listado_wks_habilitadas.lst";
	open (ARCHIVO, "> $archivo");
	{
		foreach $estaciones (@estaciones)
		{
			print ARCHIVO $estaciones;
			print ARCHIVO "\n";
		}
	}
	close (ARCHIVO);
	exit (1);
}

