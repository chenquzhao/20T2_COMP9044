#!/usr/bin/perl -w

# handle tests with "test *" or "[ * -xx * ]" or plain test string
sub format_comp{
    my $stat = $_[0];

    # preprocess statement
    $stat =~ s?^.*\(??;
    $stat =~ s?\).*$??;
    $stat =~ s?^test ??;
    $stat =~ s?\[ ??;
    $stat =~ s?\[??;
    $stat =~ s? \]??;
    $stat =~ s?\]??;
    my @words = ();
    @words = split / /, $stat;
    my $words_len = scalar @words;

    # check comparision symbol
    my $symb = "=,==,!=,-eq,-ne,-lt,-le,-gt,-ge,-e,-d,-f,-r,true";
    my $a = 0;
    my $b = -1;
    while ($a < $words_len) {
        if ($symb =~ /$words[$a]/) {
            $b++;
            last;
        }
        $a++;
    }

    # no comparision symbol -> is a regrex
    if ($b == -1) {
        my $new_stat = $stat;
        $new_stat =~ s?^(.*)$?! system "$1"?;
        return $new_stat;
    }

    my $comp = $words[$a];

    # replace comparision symbol
    if ($comp eq '=' or $comp eq '==') {
        $comp = 'eq';
    }
    elsif ($comp eq '!=') {
        $comp = 'ne';
    }
    elsif ($comp eq '-eq') {
        $comp = '==';
    }
    elsif ($comp eq '-ne') {
        $comp = '!=';
    }
    elsif ($comp eq '-lt') {
        $comp = '<';
    }
    elsif ($comp eq '-le') {
        $comp = '<=';
    }
    elsif ($comp eq '-gt') {
        $comp = '>';
    }
    elsif ($comp eq '-ge') {
        $comp = '>=';
    }
    elsif ($comp eq 'true') {
        $comp = '1';
    }

    $words[$a] = $comp;

    # add double quotes
    my $i = 0;
    while ($i < $words_len) {
        if ($i == $a) {
            $i++;
            next;
        }
        if (not $words[$i] =~ /\d+/ and not $words[$i] =~ /^[+\-*\/%]$/ and not $words[$i] =~ /^[\$@]/) {
            if (not $words[$i] =~ /^'.*'$/) {
                $words[$i] = "'$words[$i]'";
            }
        }
        $i++;
    }

    my $new_stat = join(" ", @words);
    return $new_stat;
}

# handle test combination
sub test_comb{
    my $cmd_str = $_[0];

    # break down seperator and cmds
    my @sep_list = (); # seperator list
    my @cmds = (); # cmd list
    my @words = split / /, $cmd_str;
    my $buf = "";
    foreach my $word (@words) {
        if ($word eq "-o" or $word eq "-a" or $word eq "||" or $word eq "&&") {
            push @sep_list, $word;
            $buf =~ s?\s*$??;
            push @cmds, $buf;
            $buf = "";
        }
        else {
            $buf .= "$word ";
        }
    }
    $buf =~ s?\s*$??;
    push @cmds, $buf;

    # generate output with combination symbol '||' or '&&'
    my $sep_i = 0;
    my $sep_len = scalar @sep_list;
    my $ret = "";
    foreach $cmd (@cmds) {
        $cmd =~ s?^\s*??;
        $cmd =~ s?\s*$??;
        my $new_cmd = format_comp($cmd);
        $ret .= $new_cmd;

        if ($sep_i < $sep_len) {
            my $symb = $sep_list[$sep_i];
            if ( $symb eq "-o" or $symb eq "||") {
                $ret .= " || ";
            }
            else {
                $ret .= " && ";
            }
            $sep_i++;
        }           
    }
    return $ret;
}

$more_blanks = 0; # modify the indentation
$sub_fun = 0; # 0 - not in a sub function, 1 - is in a sub function
$case_can = ""; # store the candidate of case function
$case_count = 0; # the statement id of case function
# **************** MAIN FUNCTION *******************
while ($line = <>) {
    chomp $line;

    # some early stoppings
    if ($line eq "") {
        print "\n";
        next;
    }
    # maintain comments
    elsif ($line =~ /^#[^!]/) {
        print "$line\n";
        next;
    }
    elsif ($line =~ /\bdo$/) {
        next;
    }
    elsif ($line =~ /\bthen$/) {
        next;
    }

    # handle shell case function
    if ($case_can ne "") {
        # comparision statement
        if ($line =~ /\)/) {
            my $att = $line;
            my $stat = $line;
            my $add_stat = "";

            # the cmd is following the label in a single line
            if ($line =~ /\).*\S+/) {
                $stat =~ s?^.*\) ??;
                my @res = process_line($stat, $more_blanks, $sub_fun, $case_can);
                $res_line = $res[0];
                $more_blanks = $res[1];
                $sub_fun = $res[2];
                $case_can = $res[3];

                $add_stat = $res_line;
            }

            # attempt label
            $att =~ s?\).*$??;
            $att =~ s?^\s*??;

            # generate line head
            my $head = "if";
            if ($att eq "*") {
                $line =~ s?^(\s*).*$?$1else {?;
                if ($add_stat ne "") {
                    $line .= "\n".$add_stat;
                }
                print "$line\n";
                next;
            }
            elsif ($case_count != 0) {
                $head = "elsif";
            }

            # generate output
            $line =~ s?^(\s*).*$?$1$head ("$case_can" eq $att) {?;
            if ($add_stat ne "") {
                $line .= "\n".$add_stat;
            }
            print "$line\n";
            $case_count++;
            next;
        }
        # handle semicolon
        elsif ($line =~ /;;/) {
            $line =~ s?;;?}?;
            print "$line\n";
            next;
        }
        # handle esac
        elsif ( $line =~ /esac/) {
            $case_can = "";
            $case_count = 0;
            next;
        }
        # common cmd
        else {
            my @res = process_line($line, $more_blanks, $sub_fun, $case_can);
            $res_line = $res[0];
            $more_blanks = $res[1];
            $sub_fun = $res[2];
            $case_can = $res[3];
            $line = $res_line;

            print "$line\n";
            next;
        }
    }

    # invoke process_line to handle common cmds
    my @res = process_line($line, $more_blanks, $sub_fun, $case_can);
    $res_line = $res[0];
    $more_blanks = $res[1];
    $sub_fun = $res[2];
    $case_can = $res[3];

    # handle ";" in shell
    if ( $line =~ /;/ ) {
        my $cmd_str = $line;
        $cmd_str =~ s?^\s*??;

        # seperate cmd and semicolon
        my @cmds = split /; /, $cmd_str;
        my $new_line = "";

        # translate cmd one by one
        foreach $cmd (@cmds) {
            $cmd =~ s?then ?    ?;
            my @res = process_line($cmd, $more_blanks, $sub_fun, $case_can);
            $new_cmd = $res[0];
            $more_blanks = $res[1];
            $sub_fun = $res[2];
            $case_can = $res[3];

            if ($new_line ne "") {
                $new_line .= "\n"
            }
            $new_line .= $new_cmd;

        }
        $res_line = $new_line;
    }

    # handle multiple commands combination
    # *******The head is a bit annoying, it aims at avoiding touching lines with multiple tests*********
    # *******Should be reformatted better, but leave it due to time*************************************
    if ( not $line =~ /\bif / and not $line =~ /\belif / and not $line =~ /\bwhile / and ($line =~ /&&/ or $line =~ /\|\|/ )) {
        if ($line =~ /system "/) {
            $line =~ s?system "??;
            $line =~ s?";?;?;
        }

        my $cmd_str = $line;
        $cmd_str =~ s?^\s*??;
        $cmd_str =~ s?;??g;

        # break down seperator and cmds
        my @sep_list = (); # lists of seperators
        my @cmds = (); # lists of strings
        my @words = split / /, $cmd_str;
        my $buf = "";
        foreach my $word (@words) {
            if ( $word eq "||" or $word eq "&&" ) {
                push @sep_list, $word;
                $buf =~ s?\s*$??;
                push @cmds, $buf;
                $buf = "";
            }
            else {
                $buf .= "$word ";
            }
        }
        $buf =~ s?\s*$??;
        push @cmds, $buf;

        # translate cmd line one by one
        my $tstr = "";
        my $sep_i = 0;
        my $sep_len = scalar @sep_list;
        foreach $cmd (@cmds) {
            my @res = process_line($cmd, $more_blanks, $sub_fun, $case_can);
            $new_cmd = $res[0];
            $more_blanks = $res[1];
            $sub_fun = $res[2];
            $case_can = $res[3];
            
            if ($new_cmd =~ /system/) {
                $new_cmd =~ s?system "??;
                $new_cmd =~ s?";$??;
            }
            
            $new_cmd =~ s?;$??;

            $tstr .= $new_cmd;

            # translate seperator and append it
            if ($sep_i < $sep_len) {
                my $sep = $sep_list[$sep_i];
                if ($sep eq "&&") {
                    my $post = " or ";
                    my $test_symb = "eq,ne,==,!=,>,>=,<,<=,-e,-d,-f,-r";
                    my @symb = split /,/, $test_symb;
                    foreach $ele (@symb) {
                        if ($new_cmd =~ /$ele/) {
                            $post = " and ";
                            last;
                        }
                    }
                    
                    $tstr .= $post;
                }
                else {
                    $tstr .= " or ";
                }
                $sep_i++;
            }
        }
        $line =~ s?^(\s*)(.*)$?$1$tstr;?;
        $res_line = $line;
    }
    
    if ($case_can eq "") {
        #***********************OUTPUT***********************
        print "$res_line\n";
    }
}

# main procedure of translation
sub process_line {
    my $line = $_[0];
    
    my $more_blanks = $_[1];
    my $sub_fun = $_[2];
    my $case_can = $_[3];

    # formatting head blanks
    if ($more_blanks != 0) {
        print "    "x$more_blanks;
    }

    my $sign = "ARGV";
    $sign = "_" if $sub_fun == 1;

    # translate args ONE by ONE
    while ($line =~ /\$\d+/) {
        $line =~ s?\$(\d+)?\$"$sign"[$1]?;
        my $argn = $line;
        $argn =~ s?^.*\[??;
        $argn =~ s?\].*$??;
        $argn--;
        $line =~ s?^(.*\[)\d+(\].*)$?$1$argn$2?;
    }

    # translate args advanced
    if ($line =~ /\$[#*@]/) {
        $line =~ s?\$#?\@ARGV?g;   
        $line =~ s?\$\*?join(' ', \@ARGV)?g;
        $line =~ s?\$@?\@ARGV?g;
    }

    # remove double-quotes of variable
    while ($line =~ /"\S+"/) {
        $line =~ s?^(.*)"(\S+)"(.*)$?$1$2$3?;
    }

    # translate arithmetic operation
    if ($line =~ /\bexpr /) {
        $line =~ s?\$\((.*)\)?$1?;
        $line =~ s?`??g;
        $line =~ s?'??g;
        $line =~ s?expr ??;
    }
    elsif ($line =~ /\$\(\(/) {
        $line =~ s?\(\(??;
        $line =~ s?\$??g;

        # add $ to variable
        $line =~ s?([+\-*/%]\s)([a-zA-Z]+)\b?$1\$$2?g;
        $line =~ s?=([a-zA-Z]+)\b?=\$$1?g;
        $line =~ s?test ([a-zA-Z]+)\b?test \$$1?g;

        $line =~ s?\)\)??;
    }

    # handle back quotes
    if ($line =~ /\$\(.*\)/) {
        $line =~ s?^(.*)\$\((.*)\)(.*)$?$1`$2`$3?;
    }

    # ********************* Main Procedure ***********************
    # head
    if ($line =~ /^#!/) {
        $line =~ s?^#!/.*$?#!/usr/bin/perl -w?;
    }
    # variable assignment
    elsif ($line =~ /\b\w+=\S+/) {
        if (not $line =~ /=\d+/ and not $line =~ /=\$/ and not $line =~ /=`/) {
            $line =~ s?=(.*)$?='$1'?;
        }
        $line =~ s?^(.*)\$(.*=.*)$?$1$2?;
        $line =~ s?\b(\S*)=(.*)$?\$$1 = $2;?;
    }
    # local variable
    elsif ($line =~ /\blocal /) {
        my $var = $line;
        $var =~ s?^.*local ??;
        my @vars = split / /, $var;
        foreach $ele (@vars) {
            $ele = "\$".$ele;
        }
        my $p_var = join(", ", @vars);
        $line =~ s?^(.*)local.*$?$1my ($p_var);?;
    }
    elsif ($line =~ /\bexit /) {
        $line =~ s?exit (.*)?exit $1;?;
    }
    elsif ($line =~ /\bread /) {
        $line =~ s?^(.*)read (.*)?$1\$$2 = <STDIN>;\n$1chomp \$$2;?;
    }
    elsif ($line =~ /\bcd /) {
        $line =~ s?cd (.*)?chdir '$1';?;
    }
    elsif ($line =~ /\becho / and not $line =~ /`.*echo.*`/) {
        my $paper = $line;

        # write to file, '>' or '>>'
        if ($line =~ />/) {
            my $head = $line;
            my $sym = ">";
            if ($line =~ />>/) {
                $sym = ">>";
            }

            $head =~ s?^(.*)echo(.*)$?$1?;
            $paper =~ s?^(.*)echo (.*)$?$2?;
            my $can = $paper;
            my $doc = $paper;
            $can =~ s? $sym.*$??;
            $doc =~ s?^.*$sym??;
            my $l_one = $head."open F, '$sym', $doc or die;\n";
            my $l_two = $head."print F \"$can\\n\";\n";
            my $l_three = $head."close F;";
            $line = "$l_one"."$l_two"."$l_three";
        }
        # common print
        else {
            $paper =~ s?^.*echo (.*)$?$1?;

            if ($paper =~ /^'.*'$/) {
                $paper =~ s?^'(.*)'$?$1?;
            }
            if ($paper =~ /^".*"$/) {
                $paper =~ s?^"(.*)"$?$1?;
            }

            $paper =~ s?"?\\"?g;
            if ($paper =~ /^-n/) {
                $paper =~ s?^-n ??;
                $line =~ s?^(.*)echo.*$?$1print "$paper";?;
            }
            else {
                $line =~ s?^(.*)echo.*$?$1print "$paper\\n";?;
            }
        }
    }
    elsif ($line =~ /\bfor /) {
        $line =~ s?for (.*) in (.*)$?foreach \$$1 ($2) {?;
        my $arr = $line;
        $arr =~ s?^.*\(??;
        $arr =~ s?\).*$??;
        my $str = ""; # the string that represents the iteratable object

        # collect through files
        if ($arr =~ /.*\.\w+/) {
            $str = "glob(\"$arr\")";
        }
        else {
            my @words = split / /, $arr;
            my $i = 0;
            
            while ($i < scalar @words) {
                my $word = $words[$i];
                if (not $word =~ /\d+/ and not $word =~ /^`/) {
                    $word =~ s/^(.*)$/'$1'/;
                }
                $str .= "$word";
                if ($i != $#words) {
                    $str .= ", ";
                }
                $i++;
            }
        }

        if ($arr =~ /^system/) {
            $str = $arr;
        }

        $line =~ s?^(.*\().*(\).*)$?$1$str$2?;
    }
    elsif ($line =~ /\bdone$/) {
        $line =~ s?done?}?;
    }
    elsif ($line =~ /\bif/) {
        $line =~ s?if (.*)?if ($1) {?;

        # check if is multiple tests
        if ($line =~ /-o/ or $line =~ /-a/ or $line =~ /||/ or $line =~ /&&/) {
            $line =~ s?^test ??;
            $line =~ s?\[ ??;
            $line =~ s?\[??;
            $line =~ s? \]??;
            $line =~ s?\]??;

            my $ret = test_comb($line);
            $line =~ s?^(.*\().*(\).*)$?$1$ret$2?;
        }
        else {
            # retreive comparision statement
            my $new_stat = format_comp($line);
            $line =~ s?^(.*\().*(\).*)$?$1$new_stat$2?;
        }    
    }
    elsif ($line =~ /\belif/) {
        $line =~ s?elif (.*)?    } elsif ($1) {?;

        # check if is multiple tests
        if ($line =~ /-o/ or $line =~ /-a/ or $line =~ /||/ or $line =~ /&&/) {
            $line =~ s?^test ??;
            $line =~ s?\[ ??;
            $line =~ s?\[??;
            $line =~ s? \]??;
            $line =~ s?\]??;

            my $ret = test_comb($line);
            $line =~ s?^(.*\().*(\).*)$?$1$ret$2?;
        }
        else {
            my $new_stat = format_comp($line);
            $line =~ s?^(.*\().*(\).*)$?$1$new_stat$2?;
        }
        
        $more_blanks++;
    }
    elsif ($line =~ /\belse/) {
        $line =~ s?else?\} else \{?;
    }
    elsif ($line =~ /\bwhile/) {
        $line =~ s?while (.*)?while ($1) {?;

        # check if is multiple tests
        if ($line =~ /-o/ or $line =~ /-a/ or $line =~ /||/ or $line =~ /&&/) {
            $line =~ s?^test ??;
            $line =~ s?\[ ??;
            $line =~ s?\[??;
            $line =~ s? \]??;
            $line =~ s?\]??;

            my $ret = test_comb($line);
            $line =~ s?^(.*\().*(\).*)$?$1$ret$2?;
        }
        else {
            my $new_stat = format_comp($line);
            $line =~ s?^(.*\().*(\).*)$?$1$new_stat$2?;
        }
    }
    elsif ($line =~ /\bfi$/) {
        $line =~ s?fi?\}?;
        $more_blanks-- if $more_blanks > 0;
    }
    # plain test
    elsif ($line =~ /^test/ or $line =~ /^\[.*\]$/) {
        my $new_stat = format_comp($line);
        $line = $new_stat;
    }
    # sub-function open
    elsif ($line =~ /\S\(\) \{/) {
        $line =~ s?(\S+)\(\)(.*)$?sub $1$2?;
        $sub_fun = 1;
    }
    # sub-function close
    elsif ($line =~ /\}/) {
        $sub_fun = 0;
    }
    elsif ($line =~ /\brm / and not $line =~ /rm -[a-zA-Z]/) {
        $line =~ s?^(.*)rm (.*)$?$1unlink $2?;
    }
    # elsif ($line =~ /\bls/) {
    #     # simple ls translation
    #     $line = "print join\(\"\\n\", glob\(\"*\"\)\).\"\\n\"\;";
    # }
    elsif ($line =~ /\bcase /) {
        my $can = $line;
        $can =~ s?^.*case ??;
        $can =~ s? in.*$??;
        $case_can = $can;
    }
    # direct translation
    else {
        if ($line =~ /\breturn /) {
            $line .= ";";
        }
        else {
            $line =~ s?^(\s*)(.*)$?$1system "$2";?;
        }
    }

    # reformat in-line comments
    if ($line =~ /^.*#.*;/) {
        $line =~ s?^(.*\S)(\s*#.*);$?$1;$2?;
    }

    my @ret = ($line, $more_blanks, $sub_fun, $case_can);
    return @ret;
}