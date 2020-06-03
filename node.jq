def start_of_day: . + "T00:00:00Z" | fromdateiso8601;

# Selects all releases that are "alive", meaning
# that they have been released (defined by `start`)
# and that they did not reach end-of-life yet
# (defined by `end`).
def select_alive: to_entries
  | map(select(.value.start | start_of_day < now))
  | map(select(.value.end   | start_of_day > now))
  | from_entries;

def maximal_by_property(f): to_entries
  | (map(.value | f) | max) as $mx
  | map(select((.value | f) == $mx))
  | first
  | [.]
  | from_entries;

# Removes first letter of a string. Versions are
# prefixed with "v", so we use this to remove the
# prefix and extract the version number.
def extract_version: .[1:];

# Based on `select_alive`, this selects the
# most recent release (defined by a maximal value
# in `start`).
def latest: select_alive
  | maximal_by_property(.start)
  | keys
  | first
  | extract_version;

# Extracts version names of alive releases.
# See `alive`.
def alive: select_alive | keys | map(extract_version);

def export_alive: alive | join(" ");