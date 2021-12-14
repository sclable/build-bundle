def start_of_day: . + "T00:00:00Z" | fromdateiso8601;

# Removes first letter of a string. Versions are
# prefixed with "v", so we use this to remove the
# prefix and extract the version number.
def extract_version: .[1:];

def prepend_version: "v" + .;

def singleton: [.];

def maximal_by_property(f): (map(f) | max) as $mx
  | map(select((f) == $mx))
  | first
  | singleton;

def pick(entries): . as $target
  | (entries | map({"\(.key)": $target[.value]}) | add);

# Node.js Specific Expressions

# Selects all releases that are "alive", meaning
# that they have been released (defined by `start`)
# and that they did not reach end-of-life yet
# (defined by `end`).
def node_alive: to_entries
  | map(select(.value.start | start_of_day < now))
  | map(select(.value.end   | start_of_day > now))
  | from_entries;

def node_latest: to_entries
  | maximal_by_property(.value.start)
  | from_entries
  | keys
  | first
  | extract_version;

def node_lts: to_entries
  | map(select(.value.lts != null))
  | map(select(.value.lts | start_of_day < now))
  | from_entries
  | node_latest;

# Ubuntu Specific Expressions

def ubuntu_alive: .products
  | to_entries
  | map(select(.value.supported and (.key | contains("amd64"))))
  | from_entries;

def ubuntu_lts: to_entries
  | map(select(.value.aliases | contains("lts")))
  | from_entries
  | map(.version)
  | first;

def ubuntu_current: to_entries
  | maximal_by_property(.value.version | tonumber)
  | from_entries
  | map(.version)
  | first;

# GitHub Releases Specific Expressions

def github_latest: .[0].tag_name;

# Docker Specific Expressions

def pick_versions(names): . | pick(names | map({value: "com.sclable.dependency.\(.)", key: .}));

def pick_all_versions: pick_versions(["dockle", "hadolint", "java", "node", "ubuntu", "self"]);

def labels: .config.Labels;

# Spanning Matrices

def java_matrix: $java
  | {
    lts: .most_recent_lts | tostring,
    latest: .most_recent_feature_release | tostring,
    all: .available_releases
  };

def node_matrix: $node
  | node_alive
  | {
    lts: node_lts,
    latest: node_latest,
    all: (. | keys | map(extract_version))
  };

def ubuntu_matrix: $ubuntu
  | ubuntu_alive
  | {
    lts: ubuntu_lts,
    latest: ubuntu_current,
    all: . | map(.version)
  };

# Combining Jobs

def pipeline:
  map({ "\(.tag) (Ubuntu \(.ubuntu), Node \(.node), Java \(.java))": {
    cache: {},
    tags: ["medium"],
    image: {
      name: "gcr.io/kaniko-project/executor:debug",
      entrypoint: [""]
    },
    stage: "build",
    script: ([
        "/kaniko/executor",
        "--context=.",
        "--reproducible",
        "--cache=true",
        "--build-arg DOCKLE_VERSION=\(.dockle)",
        "--build-arg HADOLINT_VERSION=\(.hadolint)",
        "--build-arg JAVA_VERSION=\(.java)",
        "--build-arg NODE_VERSION=\(.node)",
        "--build-arg UBUNTU_VERSION=\(.ubuntu)",
        "--build-arg SELF=\(.self)"
      ] +
      ([
        .tag,
        "node-v\(.node)",
	"java-v\(.java)",
	"ubuntu-v\(.ubuntu)"
      ] | map("--destination \(env.IMAGE):" + .)))
    | join(" ")
  }}) | add;

def noop: {noop: {image: env.IMAGE, script: ["true"]}};

def contains_exact(known): . as $x | known | to_entries | map({l: .value, r: $x[.key]}) | map(.l == .r) | all; 

def update_or_null(known): if contains_exact(known) then null else . end;

def trigger:
    ($latest | labels | pick_all_versions) as $latest
  | ($lts    | labels | pick_all_versions) as $lts
  |   node_matrix as $node
  |   java_matrix as $java
  | ubuntu_matrix as $ubuntu
  | {
    dockle:   ($dockle   | github_latest | extract_version),
    hadolint: ($hadolint | github_latest | extract_version),
    self:     $self
  }
  | [
    . * {java: $java.lts,    node: $node.lts,    ubuntu: $ubuntu.lts,    tag: "lts"   } | update_or_null($lts),
    . * {java: $java.latest, node: $node.latest, ubuntu: $ubuntu.latest, tag: "latest"} | update_or_null($latest)
  ]
  | map(select(. != null));
