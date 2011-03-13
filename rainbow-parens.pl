#!/usr/bin/env perl

use strict;
use warnings;

use Irssi;

use List::MoreUtils qw(zip);

use vars qw($VERSION %IRSSI);
$VERSION = '0.02';
%IRSSI = (
	authors => 'Dmitri Iouchtchenko',
	contact => 'johnnyspoon@gmail.com',
	name => 'rainbow-parens',
	description => 'Displays matching brackets using matching colours.',
	license => 'WTFPL',
);

# What needs balancing?
my %char_pairs = (
	'(' => ')',
	'[' => ']',
	'{' => '}',
);

# All the characters of interest:
my $chars = join('', map { '\\' . $_ } %char_pairs);
my $chars_regex = qr/
	\G                # From the last match spot,
	(?<text>.*?)      # take anything and then a
	(?<char>[$chars]) # character we want.
/ox;

my @colours = map { '%' . $_ } qw(b g r m y c);
my $bold_colour = '%9';
my $reset_colour = '%N';
my $error_colour = '%w%1'; # White on red.

# Keep track of what has been written, as hashes of views and lines.
my @output_lines;

# Wrap the item in the colour, and embolden.
sub apply_colour {
	my ($colour, $item) = @_;

	return "${bold_colour}${colour}${item}${reset_colour}";
}

# Colourize the brackets in matching pairs.
sub colourize {
	my ($input) = @_;

	# Strings which are separated by the brackets.
	my @resulting_text;
	# Brackets with colour paired, but not yet applied: [colour, character].
	my @resulting_parens;

	# Indices of @resulting_parens.
	my @char_stack;

	# Find all brackets.
	while ($input =~ /$chars_regex/gc) {
		my ($text, $char) = ($+{text}, $+{char});
		my $paren_colour = $error_colour; # Assume the worst.

		if (exists $char_pairs{$char}) { # Opening character.
			# Pick a colour, any colour!
			$paren_colour = $colours[@char_stack % @colours];

			push(@char_stack, scalar @resulting_parens);
		} elsif (@char_stack > 0) { # Closing character?
			if ($char_pairs{$resulting_parens[$char_stack[-1]]->[1]} eq $char) {
				# Use the same colour as the matching item on the stack.
				$paren_colour = $resulting_parens[pop(@char_stack)]->[0];
			} # No match, no pop.
		}

		push(@resulting_text, $text);
		push(@resulting_parens, [$paren_colour, $char]);
	}

	my $final_text; # The remainder of the string.
	if ($input =~ /\G(?<final_text>.*)$/g) {
		$final_text = $+{final_text};
	}

	for my $extra (@char_stack) { # Take care of any leftover brackets.
		$resulting_parens[$extra]->[0] = $error_colour;
	}

	# Apply the final colours and reassemble the string.
	my @coloured_parens = map { apply_colour(@{$_}) } @resulting_parens;
	return join('', zip(@resulting_text, @coloured_parens), $final_text);
}

# Colourize the brackets in the input line and show the results.
sub rainbow_parens {
	# Get the contents of the input line.
	my $input = Irssi::parse_special('$L');
	$input =~ s/%/%%/g; # Preserve percent signs.

	if ($input ne '') { # Ignore empty input lines.
		# Print the result.
		Irssi::active_win()->print(colourize($input), MSGLEVEL_CLIENTCRAP);

		# Find the last line and record it.
		my $view = Irssi::active_win()->view();
		my $line = $view->{buffer}->{cur_line};
		push(@output_lines, {view => $view, line => $line});
	}
}

# Remove all the lines that have been written.
sub clear_lines {
	for my $line (@output_lines) {
		$line->{view}->remove_line($line->{line});
		$line->{view}->redraw(); # Get rid of the new empty space.
	}

	@output_lines = ();
}

# Figure out what to do based on the args.
sub rainbow_parens_delegate {
	my ($args) = @_;

	if ($args =~ /-clear/) {
		clear_lines();
	} else {
		rainbow_parens();
	}
}

Irssi::command_bind('rainbow-parens', 'rainbow_parens_delegate');
