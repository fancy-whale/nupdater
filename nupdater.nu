use std log 

# Get the cadence of updates from the NUPDATER_CADENCE env var, set to 1day if not set
let $cadence = 1day
if ("NUPDATER_CADENCE" in $env) {
    let $cadence = ($env | get NUPDATER_CADENCE | parse_duration)
}

# Check if last run is more than $cadence (default 1 day) - file in $nu.default-config-dir/modules/nupdater/last_run has the last run time
let $last_run = ($nu.default-config-dir | path join "scripts/nupdater_last_run")

if not ($last_run | path exists) {
    log info "First run, updating all modules"
    let $results = (nupdate_modules)
    let $script_results = (nupdate_scripts)
    date now | save -f $last_run
    return $results | append $script_results
} else {
    let $last_run_time = (open $last_run | into datetime )
    let $time_since_last_run = ((date now) - $last_run_time)
    if ($time_since_last_run > $cadence) {
        log debug "Checking for updates"
        let $results = (nupdate_modules)
        let $script_results = (nupdate_scripts)
        date now | save -f $last_run
        return $results | append $script_results
    } else {
        log debug $"Last run was less than ($cadence) ago, skipping"
    }
}

export def nupdate_check_modules [] {
    # loop through all the packages in $nu.default-config-dir
    mut $module_updates = []
    for module in (ls ($nu.default-config-dir | path join "modules") | get name) {
        # Check if it's a git repo, continue otherwise
        if not ($"($module)/.git" | path exists) {
            log debug $"Skipping module ($module | path split | last) as it is not a git repo"
            continue
        }

        # check the branch of the folder
        let branch = git -C $module branch --show-current

        log debug $"Checking module ($module | path split | last) on branch ($branch)"
        git remote update
        # Check how many changes are there in the module
        let changes = (git -C $module rev-list --count HEAD..$"origin/($branch)")
        $module_updates = $module_updates ++ [["module", "branch", "changes"];[($module | path split | last), $branch, $changes]]
    }
    return $module_updates
}

def confirm_intent [
    intent_type = "modules"
]: nothing -> bool {
    let $user_input = (input $"Do you want to update the ($intent_type)? \(Y/n)")
    if (($user_input | str downcase) == "y") {
        return true
    } else {
        return false
    }
}

def check_git_repo [
    path
]: string -> bool {
    if ($path | path type | str ends-with "file") {
        log debug $"Skipping ($path | path split | last) as it is not a git repo"
        return false
    }
    if not (($path | path join ".git") | path exists) {
        log debug $"Skipping ($path | path split | last) as it is not a git repo"
        return false
    }
    return true
}

export def nupdate_modules [] {
    # loop through all the packages in $nu.default-config-dir
    if not (confirm_intent) {
        return []
    }
    mut $module_updates = []
    for module in (ls ($nu.default-config-dir | path join "modules") | get name) {
        # Check if it's a git repo, continue otherwise
        if not (check_git_repo $module) {
            log debug $"Skipping module ($module | path split | last) as it is not a git repo"
            continue
        }

        # check the branch of the folder
        let branch = git -C $module branch --show-current

        log debug $"Updating module ($module | path split | last) on branch ($branch)"
        # Check how many changes are there in the module
        let changes = (git -C $module rev-list --count HEAD..$"origin/($branch)")
        # do git pull on each folder in $nu.default-config-dir, check if it is up to date
        git -C $module pull
        $module_updates = $module_updates ++ [["module", "branch", "changes"];[($module | path split | last), $branch, $changes]]
    }
    return $module_updates
}

export def nupdate_scripts [] {
    # loop through all the packages in $nu.default-config-dir
    if not (confirm_intent "scripts") {
        return []
    }
    mut $script_updates = []
    for script in (ls ($nu.default-config-dir | path join "scripts") | get name) {
        # Check if it's a git repo, continue otherwise
        if not (check_git_repo $script) {
            log debug $"Skipping script ($script | path split | last) as it is not a git repo"
            continue
        }

        # check the branch of the folder
        let branch = git -C $script branch --show-current

        log debug $"Updating script ($script | path split | last) on branch ($branch)"
        # Check how many changes are there in the script
        let changes = (git -C $script rev-list --count HEAD..$"origin/($branch)")
        # do git pull on each folder in $nu.default-config-dir, check if it is up to date
        git -C $script pull
        $script_updates = $script_updates ++ [["script", "branch", "changes"];[($script | path split | last), $branch, $changes]]
    }
    return $script_updates
}
