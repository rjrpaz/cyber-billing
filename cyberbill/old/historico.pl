#!/usr/bin/perl

# $webmaster = "root\@localhost";
$apache_root = "/usr/local/apache";

# $referer = $ENV{'HTTP_REFERER'};
# $host = $ENV{'HTTP_HOST'};
# $url = $ENV{'REQUEST_URI'};

#($referer) = ($referer =~ /http:\/\/$host(.*)/);


&parse_form_data (*FORM);

#################################################################
# 'wks' contiene al ip sobre el cual se va a ejecutar la accion #
#################################################################
$wks = $FORM{'wks'};
$dia = $FORM{'dia'};
$mes = $FORM{'mes'};
$anio = $FORM{'anio'};

if ($wks eq "")
{
	&return_error (500, "Error en el Proceso",
		" No se ha seleccionado una Estaci&oacute;n de Trabajo sobre la cual
		se realizar&aacute; el Reporte");
	exit;
}

$ARCHIVO= $apache_root."/logs/tarifacion";

$dia_de_hoy = `/bin/date +%d`;
$mes_actual = `/bin/date +%m`;
$anio_actual = `/bin/date +%Y`;

if (($dia != $dia_de_hoy) && ($mes != $mes_actual) &&($anio != $anio_actual))
{
	$ARCHIVO = $ARCHIVO."-".$anio.$mes.$dia;
}
$ARCHIVO = $ARCHIVO.".log";

open ARCHIVO or die &return_error (500, "Atenci&oacute;n",
		" No se encuentran registros para la fecha especificada");

print "Content-type: text/html\n\n";
#print "Content-type: text/plain\n\n";
print "<HTML>\n<TITLE>";
print "Reporte del Equipo ",$wks," Fecha: ",$dia,"/",$mes,"/",$anio;
print "</TITLE>\n<BODY>\n";
print "<TABLE BORDER=1 ALIGN=\"CENTER\">\n";
print "<TR><TD>Hora Inicio Sesi&oacute;n</TD>\n<TD>Hora Fin Sesi&oacute;n</TD>\n<TD>Tiempo Acumulado</TD></TR>\n";

$wks = `/bin/grep $wks /etc/cyberbill.conf`;
($wks) = ($wks =~ /([^\s]*)/);

$total_tiempo_acumulado = 0;
$begin = "";
$end = "";

while (<ARCHIVO>)
{
	chop;
	if (/$wks/)
	{
		if (/begins/)
		{
			($begin) = ($_ =~ /time:\s([^\n]*)/);
# GMT
			$begin = $begin - 10800
		}
		elsif (/ends/)
		{
			($end) = ($_ =~ /time:\s([^\n]*)/);
# GMT-3
			$end = $end - 10800
		}

		if (($begin ne "") && ($end ne ""))
		{
			print "<TR><TD>";
			@hora = gmtime($begin);
			print $hora[2],":";	
			$minutos = sprintf("%02d",$hora[1]);
			print $minutos,"</TD>\n<TD>";
			@hora = gmtime($end);
			print $hora[2],":";
			$minutos = sprintf("%02d",$hora[1]);
			print $minutos,"</TD>\n<TD ALIGN=\"right\">";
			$diferencia = $end - $begin;
			$total_tiempo_acumulado = $total_tiempo_acumulado + $diferencia;
			@hora = gmtime($diferencia);
			print $hora[2],":";
			$minutos = sprintf("%02d",$hora[1]);
			print $minutos,"</TD></TR>\n";
			$begin = "";
			$end = "";
		}
	}
}

if (($begin ne "") && ($end eq ""))
{
	print "<TR><TD>";
	@hora = gmtime($begin);
	print $hora[2],":";	
	$minutos = sprintf("%02d",$hora[1]);
	print $minutos,"</TD>\n<TD>";
	if ($ARCHIVO =~ m/tarifacion.log/)
	{
		print "Actualmente en uso";
	}
	else
	{
		print "Informaci&oacute;n en<BR>otro archivo";
	}
	print "</TD>\n<TD>?</TD></TR>\n";
}

@hora = gmtime($total_tiempo_acumulado);
print "<TR><TD></TD>\n<TD><B>Total Acumulado</B></TD>\n<TD ALIGN=\"right\">",$hora[2],":";
$minutos = sprintf("%02d",$hora[1]);
print $minutos,"</TD></TR>\n";

close (ARCHIVO);
print "</TABLE>\n";
print "</BODY>\n</HTML>";
exit;



sub parse_form_data
{
    local (*FORM_DATA) = @_;
    local ( $request_method, $query_string, @key_value_pairs,
                  $key_value, $key, $value);

    $request_method = $ENV{'REQUEST_METHOD'};
    if ($request_method eq "GET") {
        $query_string = $ENV{'QUERY_STRING'};
    } elsif ($request_method eq "POST") {
        read (STDIN, $query_string, $ENV{'CONTENT_LENGTH'});
    } else {
        &return_error (500, "Error en el Server",
                            " El Server utiliza un m&eacute;todo no soportado");
    }

    @key_value_pairs = split (/&/, $query_string);
    foreach $key_value (@key_value_pairs) {
        ($key, $value) = split (/=/, $key_value);
        $value =~ tr/+/ /;
        $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;

        if (defined($FORM_DATA{$key})) {
            $FORM_DATA{$key} = join ("\0", $FORM_DATA{$key}, $value);
        } else {
                    $FORM_DATA{$key} = $value;
        }
    }
}

sub return_error
{
    local ($status, $keyword, $message) = @_;
    print "Content-type: text/html", "\n";
    print "Status: ", $status, " ", $keyword, "\n\n";
    print <<End_of_Error;
<HTML>
<HEAD>
    <TITLE>CyberBill - Error Inesperado</TITLE>
</HEAD>
<BODY>
<H1>$keyword</H1>
<HR>$message<HR>
Por favor, contactenos telefonicamente para mayor informacion.
</BODY>
</HTML>
End_of_Error
    exit(1);
}

