#!/usr/bin/env perl

use strict;
use warnings;

use Irssi;
use Irssi::TextUI;

use List::MoreUtils qw(zip);

use vars qw($VERSION %IRSSI);
$VERSION = '0.03';
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

# Signals to catch when the script is active.
my @signals = (
	['gui key pressed', 'update_rainbow_parens'],
	['window changed', 'update_rainbow_parens'],
);

# Keep track of the colourized line as a hashref with the view and line.
my $colourized_line;

# Whether the script is active.
my $on = 0;

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
		$colourized_line = {view => $view, line => $line};
	}
}

# Remove all the lines that have been written.
sub clear_line {
	if ($colourized_line) {
		$colourized_line->{view}->remove_line($colourized_line->{line});
		$colourized_line->{view}->redraw(); # Get rid of the new empty space.

		$colourized_line = undef;
	}
}

# Update the colourized line in response to some change.
sub update_rainbow_parens {
	clear_line();
	rainbow_parens();
}

# Toggle rainbow-parens.
sub rainbow_parens_toggle {
	if ($on) { # Disable.
		$on = 0;

		for my $s (@signals) {
			Irssi::signal_remove($s->[0], $s->[1]);
		}

		clear_line();
	} else { # Enable.
		$on = 1;

		rainbow_parens();

		for my $s (@signals) {
			Irssi::signal_add_last($s->[0], $s->[1]);
		}
	}
}

Irssi::command_bind('rainbow-parens-toggle', 'rainbow_parens_toggle');
