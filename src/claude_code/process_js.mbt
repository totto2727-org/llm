///|
async fn collect_output(
  program : String,
  args : Array[String],
) -> (Int32, String, String) {
  let (code, stdout, stderr) = @x_process.collect_output(program, args)
  (code, stdout.text(), stderr.text())
}
