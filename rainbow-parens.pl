#!/usr/bin/env perl

use strict;
use warnings;

use Irssi;
use Irssi::TextUI;

use List::MoreUtils qw(zip);
use POSIX qw(ceil);

use vars qw($VERSION %IRSSI);
$VERSION = '0.07';
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
my $chars = join('', map { "\\$_" } %char_pairs);
my $chars_regex = qr/
	\G                # From the last match spot,
	(?<text>.*?)      # take anything and then a
	(?<char>[$chars]) # character we want.
/ox;

my @colours = map { "%$_" } qw(b g r m y c);
my $bold_colour = '%9';
my $reset_colour = '%N';
my $error_colour = '%w%1'; # White on red.

# Window management.
my $window_name = $IRSSI{name};
my $min_refnum = 99;
# If the script was restarted, try to find the window it was using.
my $rainbow_window = Irssi::window_find_name($window_name);
my ($min_lines, $max_lines); # From settings.

# Function-specific global state.
my $current_line;
my $close_on_typing = 0;

# Wrap the item in the colour, and embolden.
sub apply_colour {
	my ($colour, $item) = @_;

	return "${bold_colour}${colour}${item}${reset_colour}";
}

# Colourize the brackets in matching pairs.
sub colourize {
	my @input_lines = @_;

	# Strings which are separated by the brackets.
	my @resulting_text;
	# Brackets with colour paired, but not yet applied: [colour, character].
	my @resulting_parens;
	# Remainders of the strings.
	my @final_text;

	# Indices of @resulting_parens.
	my @char_stack;

	while (my ($i, $input) = each(@input_lines)) {
		push(@resulting_text, []);
		push(@resulting_parens, []);

		# Find all brackets.
		while ($input =~ /$chars_regex/gc) {
			my ($text, $char) = ($+{text}, $+{char});
			my $paren_colour = $error_colour; # Assume the worst.

			if (exists $char_pairs{$char}) { # Opening character.
				# Pick a colour, any colour!
				$paren_colour = $colours[@char_stack % @colours];

				push(@char_stack, [$i, scalar @{$resulting_parens[$i]}]);
			} elsif (@char_stack > 0) { # Closing character?
				# Figure out which character we're looking at.
				my ($line, $paren) = @{$char_stack[-1]};
				my $stack_char = $resulting_parens[$line][$paren];

				if ($char_pairs{$stack_char->[1]} eq $char) {
					pop(@char_stack);

					# Use the same colour as the matching item on the stack.
					$paren_colour = $stack_char->[0];
				} # No match, no pop.
			}

			push(@{$resulting_text[-1]}, $text);
			push(@{$resulting_parens[-1]}, [$paren_colour, $char]);
		}

		if ($input =~ /\G(?<final_text>.*)$/g) {
			push(@final_text, $+{final_text});
		} else {
			push(@final_text, '');
		}
	}

	for my $extra (@char_stack) { # Take care of any leftover brackets.
		my ($line, $paren) = @{$extra};
		my $stack_char = $resulting_parens[$line][$paren];
		$stack_char->[0] = $error_colour;
	}

	my @result_lines;
	for my $i (0..$#input_lines) {
		# Apply the final colours and reassemble the string.
		my @coloured_parens = map { apply_colour(@{$_}) } @{$resulting_parens[$i]};
		push(@result_lines, join('', zip(@{$resulting_text[$i]}, @coloured_parens), $final_text[$i]));
	}
	return @result_lines;
}

# Colourize the brackets in the input line and show the results.
sub rainbow_parens {
	return unless $rainbow_window; # Shouldn't happen, really.

	my $input;
	if ($current_line) {
		# Get the context of the selected output line.
		$input = $current_line->get_text(0);
	} else {
		# Get the contents of the input line.
		$input = Irssi::parse_special('$L');
	}
	$input =~ s/%/%%/g; # Preserve percent signs.

	# Split the input into lines that fit the window.
	my $w = $rainbow_window->{width};
	my @input_lines = ($input =~ /.{1,${w}}/go);

	# Show the result.
	$rainbow_window->command('clear');
	$rainbow_window->print($_, MSGLEVEL_NEVER) for colourize(@input_lines);

	# Set window to the appropriate size.
	my $required_lines = @input_lines;
	if ($required_lines < $min_lines) {
		$required_lines = $min_lines;
	} elsif ($required_lines > $max_lines) {
		$required_lines = $max_lines;
	}
	if ($rainbow_window->{height} != $required_lines) {
		$rainbow_window->command("window size $required_lines");
	}
}

# Open the preview window.
sub open_window {
	return if $rainbow_window;

	my $lastwin = Irssi::active_win(); # Will need to restore focus later.

	$rainbow_window = Irssi::Windowitem::window_create(0, 0);

	# Claim the name unconditionally; should be unique enough.
	$rainbow_window->set_name($window_name);

	# Ensure we're not treading on anyone for the refnum though.
	my $last_refnum = Irssi::windows_refnum_last();
	if ($last_refnum + 1 >= $min_refnum) { # Big enough.
		$rainbow_window->set_refnum($last_refnum + 1);
	} else {
		$rainbow_window->set_refnum($min_refnum);
	}

	# Show the window, and give back focus.
	$lastwin->set_active();
	$lastwin->command("window show $window_name");
	$lastwin->set_active();

	# Resize later as needed.
	$rainbow_window->command("window size $min_lines");
}

# Close the preview window.
sub close_window {
	return unless $rainbow_window;

	$rainbow_window->destroy();

	$rainbow_window = undef;

	$current_line = undef; # Drop back to the input line.
}

# Close the preview window after rainbow_parens_once.
sub close_on_typing {
	if ($close_on_typing) {
		Irssi::signal_remove('gui key pressed' => 'close_on_typing');

		close_window();
	} else {
		# The signal is set up in response to a key press, so skip the first run.
		$close_on_typing = 1;
	}
}

# Toggle temporary, once-view rainbow-parens.
sub rainbow_parens_once {
	return if $rainbow_window; # To do otherwise would be silly.

	open_window();
	rainbow_parens();

	# Prepare the window to be closed upon the next keystroke.
	$close_on_typing = 0;
	Irssi::signal_add_last('gui key pressed' => 'close_on_typing');
}

# Toggle permanent, live-view rainbow-parens.
sub rainbow_parens_toggle {
	if ($rainbow_window) {
		Irssi::signal_remove('gui key pressed' => 'rainbow_parens');

		close_window();
	} else {
		open_window();

		Irssi::signal_add_last('gui key pressed' => 'rainbow_parens');
	}
}

# Switch to the next line in the output buffer.
sub rainbow_parens_next {
	return unless $current_line;

	my $next = $current_line->next();
	if ($next) {
		$current_line = $next;
	} else {
		$current_line = undef; # No next line, so back to the input line.
	}
}

# Switch to the previous line in the output buffer.
sub rainbow_parens_prev {
	if ($current_line) {
		my $prev = $current_line->prev();
		if ($prev) {
			$current_line = $prev;
		} # else { Stay on the first line. }
	} else {
		# Obtain the last line in the current window.
		$current_line = Irssi::active_win()->view()->{buffer}{cur_line};
	}
}

# Try to ensure the setting name is unique.
sub gen_setting_name {
	my ($setting) = @_;

	return "$IRSSI{name}-$setting";
}

# Grab the settings from Irssi.
sub load_settings {
	$min_lines = Irssi::settings_get_int(gen_setting_name('min_lines'));
	$max_lines = Irssi::settings_get_int(gen_setting_name('max_lines'));
}

# Obtain and verify any new settings.
Irssi::signal_add_last('setup changed' => sub {
	load_settings();

	my @problems;

	if ($min_lines <= 1) {
		push @problems, 'min_lines <= 1: Irssi does not appear to support single-line windows.';
	}
	if ($max_lines < $min_lines) {
		push @problems, 'max_lines < min_lines: So confused!';
	}

	if (@problems) {
		print $IRSSI{name}, ' configuration problems:';

		for my $problem (@problems) {
			print ' ' x 4, $problem;
		}
	}
});

Irssi::command_bind('rainbow-parens-once', 'rainbow_parens_once');
Irssi::command_bind('rainbow-parens-toggle', 'rainbow_parens_toggle');
Irssi::command_bind('rainbow-parens-prev', 'rainbow_parens_prev');
Irssi::command_bind('rainbow-parens-next', 'rainbow_parens_next');

Irssi::settings_add_int($IRSSI{name}, gen_setting_name('min_lines'), 2);
Irssi::settings_add_int($IRSSI{name}, gen_setting_name('max_lines'), 8);

load_settings();
