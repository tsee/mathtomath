package Generic_out;
#define the output in generic format

use 5.10.1;
use strict;
use Data::Dump;
#----------------------------------------------------------------------------------------------------

#operator precedence
# brackets should also be included here to indicate that they are legal
my %op_prec=(
    ',' => 1,
    '=' => 2,
    '==' => 2,
    '!=' => 2,
    '<' => 2,
    '<=' => 2,
    '>' => 2,
    '>=' => 2,
    '+' => 3,
    '-' => 3,
    '*' => 4,
    '/' => 4,
    '^' => 5,
    '.' => 6,
    '?' => 7,
    '??' => 7,
    '???' => 7,
    '[' => undef,
    ']' => undef,
    '(' => undef,
    ')' => undef,
    '{' => undef,
    '}' => undef
    );

#special treatment for operators
my %special_fun=(
    '?' => \&postfix_operator_to_string,
    '??' => \&postfix_operator_to_string,
    '???' => \&postfix_operator_to_string
);

sub to_string{
    #get rid of the module name in the first (non-recursive) call
    # AND ASK STEFFEN HOW TO DO THIS PROPERLY
#    my $format= shift;
    shift if $_[0] eq 'Generic_out';
    
    my $tree=shift;
    # say "to_string";
    #dd($tree);
    my $last_prec=shift;
    defined $last_prec or $last_prec=0;
    my $string;
    #special treatment for some operators/functions/whatever
    if (defined $special_fun{$tree->name}){
	return &{$special_fun{$tree->name}}($tree->name,$tree->args,$last_prec)
    }

    given($tree->is){
	when('number') {$string= number_to_string($tree->name)}
	when('symbol') {$string= symbol_to_string($tree->name)}
	when('operator') {
	    $string=operator_to_string($tree->name,$tree->args, $last_prec);
	}
	when('bracket') {
	    $string= bracket_to_string($tree->name,$tree->args)
	}
	default {die "Don't know how to format a '$tree->{is}' as a string in format 'generic'"}
    }
    return $string;
}

#format a symbol/number/operator/bracket as a string, either ignoring all illegal tokens
# TODO: or dying on error
sub symbol_to_string{
    $_=$_[0];
    #treat special symbols
    s/(^\*\*|\*\*$)//g;
    #delete illegal tokens
    s/\W+//g;
    s/^[[:^alpha:]]+//g;
    $_ or die "Symbol '$_[0]' can't be converted into the format 'generic', because it does not contain any legal tokens";
    return $_;
}

sub number_to_string{
    $_=$_[0];
    s/[^\d\.]//g;
    /^(\d+|\d*\.\d+|\d+\.\d*)$/ 
	or die "Number '$_[0]' can't be converted into the format 'generic'";
    $_=$1;
    if(/^\./){$_='0'.$_}
    elsif(/\.$/){$_.='0'}
    return $_;
}

# sub function_to_string{
#     my $function=shift;
#     my $args=shift;
#     return(to_string($function).$fun_brackets[0].to_string($args).$fun_brackets[1])
# }

sub operator_to_string{
    my $operator=shift;
    my $args=shift;
    my $last_prec=shift;
    my $string;
    #check whether the operator exists in this format
    exists $op_prec{$operator} 
    or die "Don't know how to format operator '$operator' in generic format"; 
    if(scalar @$args == 1){
	# by default, operators with one argument are prefix operators
	$string= prefix_operator_to_string($operator,$args); 
    }
    else{
	$string = infix_operator_to_string($operator,$args);
    }
    $string='('.$string.')' if ($last_prec > $op_prec{$operator});
    return $string
}

sub prefix_operator_to_string{
    my $operator=shift;
    my $args=shift;
    my $last_prec=shift;
    return $operator.to_string($$args[0],$op_prec{$operator});
}

sub postfix_operator_to_string{
    my $operator=shift;
    my $args=shift;
    my $last_prec=shift;
    return to_string($$args[0],$op_prec{$operator}).$operator;
}

sub infix_operator_to_string{
    my $operator=shift;
    my $args=shift;
    my $last_prec=shift;
    return join($operator, map {to_string($_,$op_prec{$operator})} @$args);
}

sub bracket_to_string{
    my $brackets=shift;
    my $args=shift;
    scalar @$args<3 or die;
    #check whether the brackets are legal tokens in this format
    for(my $i=0;$i<2;++$i){
	exists $op_prec{$brackets->[$i]} 
	or die "Don't know how to format bracket '$_[0]->[$i]' in generic format"; 
    }
    return((scalar @$args>1?to_string($args->[0]):'').$brackets->[0].to_string($args->[-1]).$brackets->[1])
}

1;