# Get the cadence of updates from the NUPDATER_CADENCE env var, set to 1day if not set
let $cadence = 1day
if ("NUPDATER_CADENCE" in $env) {
    let $cadence = ($env | get NUPDATER_CADENCE | parse_duration)
}

# Check if last run is more than $cadence (default 1 day) - file in $nu.default-config-dir/modules/nupdater/last_run has the last run time
let $last_run = ($nu.default-config-dir | path join "scripts/nupdater_last_run")

if not ($last_run | path exists) {
    print "First run, updating all modules"
    let $results = (nupdate_modules)
    date now | save -f $last_run
    return $results
} else {
    let $last_run_time = (open $last_run | into datetime )
    let $time_since_last_run = ((date now) - $last_run_time)
    if ($time_since_last_run > $cadence) {
        print "Checking for updates"
        let $results = (nupdate_modules)
        date now | save -f $last_run
        return $results
    } else {
        print $"Last run was less than ($cadence) ago, skipping"
    }
}

export def nupdate_check_modules [] {
    # loop through all the packages in $nu.default-config-dir
    mut $module_updates = []
    for module in (ls ($nu.default-config-dir | path join "modules") | get name) {
        # Check if it's a git repo, continue otherwise
        if not ($"($module)/.git" | path exists) {
            print $"Skipping module ($module | path split | last) as it is not a git repo"
            continue
        }

        # check the branch of the folder
        let branch = git -C $module branch --show-current

        print $"Checking module ($module | path split | last) on branch ($branch)"
        git remote update
        # Check how many changes are there in the module
        let changes = (git -C $module rev-list --count HEAD..$"origin/($branch)")
        $module_updates = $module_updates ++ [["module", "branch", "changes"];[($module | path split | last), $branch, $changes]]
    }
    return $module_updates
}

export def nupdate_modules [] {
    # loop through all the packages in $nu.default-config-dir
    mut $module_updates = []
    for module in (ls ($nu.default-config-dir | path join "modules") | get name) {
        # Check if it's a git repo, continue otherwise
        if not ($"($module)/.git" | path exists) {
            print $"Skipping module ($module | path split | last) as it is not a git repo"
            continue
        }

        # check the branch of the folder
        let branch = git -C $module branch --show-current

        print $"Updating module ($module | path split | last) on branch ($branch)"
        # Check how many changes are there in the module
        let changes = (git -C $module rev-list --count HEAD..$"origin/($branch)")
        # do git pull on each folder in $nu.default-config-dir, check if it is up to date
        git -C $module pull
        $module_updates = $module_updates ++ [["module", "branch", "changes"];[($module | path split | last), $branch, $changes]]
    }
    return $module_updates
}

