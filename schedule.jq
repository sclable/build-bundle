# For Node releases, see:
# - https://github.com/nodejs/Release#release-schedule
# - https://nodejs.org/download/release/

def start_of_day: . + "T00:00:00Z" | fromdateiso8601;

# Removes first letter of a string. Versions are
# prefixed with "v", so we use this to remove the
# prefix and extract the version number.
def extract_version: .[1:];

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
  | [.]
  | from_entries;

def latest_version: maximal_by_property(.start)
  | keys
  | first
  | extract_version;

def current: latest_version;

def lts: select_lts | latest_version;

def keytotag: to_entries
  | map(. * {value: {tags: ["node-\(.key)"]}})
  | from_entries;

def node_versions_to_jobs: to_entries
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
      (.value.tags | map("--destination \(env.IMAGE):\(.)"))
    | join(" "))
  }};

select_alive |
current as $current |
lts as $lts |
keytotag |
."v\(lts)".tags += ["lts"] |
."v\(current)".tags += ["current"] |
node_versions_to_jobs
