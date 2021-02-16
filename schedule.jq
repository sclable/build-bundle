# For Node releases, see:
# - https://github.com/nodejs/Release#release-schedule
# - https://nodejs.org/download/release/

def start_of_day: . + "T00:00:00Z" | fromdateiso8601;

# Removes first letter of a string. Versions are
# prefixed with "v", so we use this to remove the
# prefix and extract the version number.
def extract_version: .[1:];

def prepend_version: "v" + .;

def singleton: [.];

# Selects all releases that are "alive", meaning
# that they have been released (defined by `start`)
# and that they did not reach end-of-life yet
# (defined by `end`).
def select_alive: to_entries
  | map(select(.value.start | start_of_day < now))
  | map(select(.value.end   | start_of_day > now))
  | from_entries;

def select_lts: to_entries
  | map(select(.value.lts != null))
  | map(select(.value.lts | start_of_day < now))
  | from_entries;

def maximal_by_property(f): to_entries
  | (map(.value | f) | max) as $mx
  | map(select((.value | f) == $mx))
  | first
  | singleton
  | from_entries;

def latest: maximal_by_property(.start)
  | keys
  | first
  | extract_version;

def current: latest;

def lts: select_lts | latest;

def key_to_tag: to_entries
  | map(. * {value: {tags: ["node-\(.key)"]}})
  | from_entries;

def add_tags: key_to_tag
  | .[lts     | prepend_version].tags += ["lts"]
  | .[current | prepend_version].tags += ["latest"];

def to_jobs: to_entries
  | { "build": {
    cache: {},
    tags: ["build-cluster", "sclable"],
    image: {
      name: "gcr.io/kaniko-project/executor:debug",
      entrypoint: [""]
    },
    stage: "build",
    script: map([
        "/kaniko/executor",
        "--context=.",
        "--reproducible",
        "--cache=true",
        "--build-arg NODE_VERSION=\(.key | extract_version)"
      ] +
      (.value.tags | map("--destination \(env.IMAGE):" + .))
    | join(" "))
  }};

$node | select_alive | add_tags | to_jobs
