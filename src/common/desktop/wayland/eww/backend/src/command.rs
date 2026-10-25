use std::process::Command;

// External tools have bounded runtimes; stdout is drained while they run.
pub fn run(command: &str, args: &[&str]) -> Option<String> {
    let result = Command::new("timeout")
        .args(["3", command])
        .args(args)
        .env("LC_ALL", "C")
        .output()
        .ok()?;
    result
        .status
        .success()
        .then(|| String::from_utf8_lossy(&result.stdout).trim().to_string())
}
