#!/usr/bin/perl

#$apache_root = "/usr/local/apache-root";
$apache_root = "/usr/local/apache";

$url = "/cyber/index.html";
$http_referer = $ENV{'HTTP_REFERER'};
# $host = $ENV{'HTTP_HOST'};


$ipchains = "/sbin/ipchains ";
$date = `/bin/date +%s`;

if ($http_referer =~ /$url/)
{

	&parse_form_data (*FORM);

	#################################################################
	# 'wks' contiene al ip sobre el cual se va a ejecutar la accion #
	#################################################################
	$wks = $FORM{'wks'};

	############################################
	# 'accion' contiene la accion a ejecutarse #
	# 'habilitar' o 'deshabilitar'             #
	############################################
	$accion = $FORM{'accion'};

	$bandera = "no";
	#######################################################
	# Se fija se el ip figura en la lista de "aceptados"  #
	# Si no figura, la bandera vale "no". Caso contrario, #
	# vale "si".                                          #
	#######################################################
	open (IPCHAINS, "/sbin/ipchains -nL input |/bin/grep ^ACCEPT |/bin/awk '{print \$4}' |");
	while (<IPCHAINS>)
	{
		chop;
		if ($wks eq $_)
		{
			$bandera = "si";
		}
	}
	close (IPCHAINS);

	##################################################################
	# Este flag indica si se debe asentar alguna operacion en el log #
	##################################################################
	$escribir_log = "no";

		if (($accion eq "deshabilitar") && ($bandera eq "si"))
		{
			system ("$ipchains -D input -s $wks -d 0/0 -j ACCEPT");
			$escribir_log = "si";
			$frase = "$wks ends session time: $date"
		}
		if (($accion eq "habilitar") && ($bandera eq "no"))
		{
			system ("$ipchains -I input 3 -s $wks -d 0/0 -j ACCEPT");
			$escribir_log = "si";
			$frase = "$wks begins session time: $date"
		}

		if (($escribir_log eq "si"))
		{
			open (LOG, ">>$apache_root/logs/tarifacion.log");
			{
				print LOG $frase;
			}
			close (LOG);
		}
}	
&default;
exit;



######################
# Pagina por defecto #
######################
sub default 
{

	##########################################################################
	# Este parametro indica el numero de columnas que va a tener la pantalla #
	##########################################################################
	$p_nro_columnas = 4;

	#########################################################################
	# Este parametro indica el tamanio en pixels que van a tener los iconos #
	#########################################################################
	$p_image_size = 100;

	print "Content-type: text/html\n\n";
	print <<EOF_TITLE;
<HTML>
<TITLE>Programa Tarifaci&oacute;n CyberBar</TITLE>
<HEAD>

<META HTTP-EQUIV="REFRESH" CONTENT="60">
</HEAD>
<BODY>
<H1>Estado actual de las Estaciones de Trabajo</H1>
EOF_TITLE


	$contador = 0;
	open (IPCHAINS, "/sbin/ipchains -nL input|/bin/grep ^ACCEPT |/bin/awk '{print \$4}' |");
	while (<IPCHAINS>)
	{
		chop;
		$habilitadas[$contador] = $_;
		$contador++;
	}
	close (IPCHAINS);


	print "<FORM NAME=\"Tarifacion\">";
	print "<TABLE BORDER=1><TR>\n";

	##############################################################
	# Abre el archivo de configuracion de los puestos de trabajo #
	##############################################################
	open (WKS, "/bin/grep -v ^# /etc/cyberbill.conf |");
	$nro_columna = 1;
	################################################################
	# Esta variable va guardando la segunda linea de la tabla, con #
	# los textos correspondientes a cada icono                     #
	################################################################
	$pie_icono = "";
	while (<WKS>)
	{
		chop;
		if ($_ ne "")
		{
			$bandera = "no";
			($ip, $hostname) = split /\s+/, $_;

			##################################################################
			# Se fija si cada "ip" del archivo de configuracion figura en la #
			# lista de las reglas que estan en este momento. Si figuran,     #
			# utiliza una bandera que vale "si", caso contrario vale "no"    #
			##################################################################  
			foreach $habilitadas (@habilitadas)
			{
				if ($ip eq $habilitadas)
				{
					$bandera = "si";
				}
			}

			print "<TD><CENTER><A HREF=\"index.html\?wks=$ip&accion=";

			###################################################################
			# Si este ip NO FIGURA en la lista de direcciones habilitadas, el #
			# link apunta al script con parametros para posibilitar su        #
			# HABILITACION                                                    #
			###################################################################
			if ($bandera eq "no")
			{
				print "habilitar\">\n<IMG SRC=\"/icons/red.png\" WIDTH=\"$p_image_size\"><BR><BR>";
				$pie_icono = $pie_icono."<TD><CENTER>$hostname deshabilitada<BR>";

				##########################################################
				# Al estar deshabilitada, muestra el tiempo de la ultima #
				# sesion                                                 #
				##########################################################
				$hora_inicio = `/bin/grep $ip /usr/local/apache/logs/tarifacion.log |/bin/grep begins |/usr/bin/tail -n 1 |/usr/bin/cut -d " " -f 5`;
				$hora_fin = `/bin/grep $ip /usr/local/apache/logs/tarifacion.log |/bin/grep ends |/usr/bin/tail -n 1 |/usr/bin/cut -d " " -f 5`;
				$diferencia = $hora_fin - $hora_inicio;		
				if (($hora_inicio ne "") && ($hora_fin ne "") && ($diferencia > 30))
				{
					$pie_icono = $pie_icono."Tiempo de la <B>&uacute;ltima<BR>sesi&oacute;n</B>:<BR>";
					$hora = $diferencia / 3600;
					$hora = sprintf ("%.0f", $hora);
					##########################################################
					# Debido al redondeo, si la cantidad de segundos que son #
					# el resto del calculo de las horas superan la media     #
					# hora (1800 segundos), se resta 1 a la cantidad de      #
					# horas obtenidas                                        #
					##########################################################
					$diferencia = $diferencia % 3600;
					if ($diferencia > 1800)
					{
						$hora--;
					}
					$minutos = $diferencia / 60;
					$minutos = sprintf ("%.0f", $minutos);
					if ($hora != 0)
					{
						$pie_icono = $pie_icono.$hora." hora";
						if ($hora != 1)
						{
							$pie_icono = $pie_icono."s";
						}
						$pie_icono = $pie_icono.", ";
					}
					if ($minutos != 0)
					{
						$pie_icono = $pie_icono.$minutos." minuto";
						if ($minutos != 1)
						{
							$pie_icono = $pie_icono."s";
						}
					}
					$pie_icono = $pie_icono."<BR>";
				}
				$pie_icono = $pie_icono."</CENTER></TD>";
			}
			else #if ($bandera eq "no")
			{
				################################################################
				# Si este ip FIGURA en la lista de direcciones habilitadas, el #
				# link apunta al script con parametros para posibilitar su     #
				# DESHABILITACION                                              #
				################################################################
				print "deshabilitar\">\n<IMG SRC=\"/icons/green.png\" WIDTH=\"$p_image_size\"><BR><BR>";
				$pie_icono = $pie_icono."<TD><CENTER>$hostname habilitada<BR>";

				##############################################################
				# Al estar habilitada, muestra el tiempo de la sesion actual #
				##############################################################
				$hora_inicio = `/bin/grep $ip /usr/local/apache/logs/tarifacion.log |/bin/grep begins |/usr/bin/tail -n 1 |/usr/bin/cut -d " " -f 5`;
				$hora_actual = `/bin/date +%s`;
				$diferencia = $hora_actual - $hora_inicio;		
				if (($hora_inicio ne "") && ($hora_actual ne "") && ($diferencia > 30))
				{
					$pie_icono = $pie_icono."Tiempo de la <B>sesi&oacute;n<BR>actual</B>:<BR>";
					$hora = $diferencia / 3600;
					$hora = sprintf ("%.0f", $hora);
					##########################################################
					# Debido al redondeo, si la cantidad de segundos que son #
					# el resto del calculo de las horas superan la media     #
					# hora (1800 segundos), se resta 1 a la cantidad de      #
					# horas obtenidas                                        #
					##########################################################
					$diferencia = $diferencia % 3600;
					if ($diferencia > 1800)
					{
						$hora--;
					}
					$minutos = $diferencia / 60;
					$minutos = sprintf ("%.0f", $minutos);
					if ($hora != 0)
					{
						$pie_icono = $pie_icono.$hora." hora";
						if ($hora != 1)
						{
							$pie_icono = $pie_icono."s";
						}
						$pie_icono = $pie_icono.", ";
					}
					if ($minutos != 0)
					{
						$pie_icono = $pie_icono.$minutos." minuto";
						if ($minutos != 1)
						{
							$pie_icono = $pie_icono."s";
						}
					}
					$pie_icono = $pie_icono."<BR>";
				}
				$pie_icono = $pie_icono."</CENTER></TD>";
			} #if ($bandera eq "no")

			print "</A></CENTER></TD>\n";
			$nro_columna++;
			if (($nro_columna % ($p_nro_columnas + 1)) == 0)
			{
				print "</TR>\n<TR>";
				print $pie_icono;
				print "</TR>\n<TR>";
				$pie_icono = "";
				$nro_columna++
			}

		}
	}
	close (WKS);

	###################################################
	# A partir de la ultima PC, rellena la tabla HTML #
	##################################################
	while (($nro_columna % ($p_nro_columnas + 1)) != 0)
	{
		print "<TD></TD>";
		$pie_icono = $pie_icono."<TD></TD>";
		$nro_columna++
	}
	print "</TR><TR>\n";
	print $pie_icono;

	print "</TR></TABLE>\n";
	print "</FORM>\n";

	print "<BODY>\n";
	exit;
}



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

