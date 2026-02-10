# ISTAT Download Result Structure

An `istat_result` object is a list with the following components:

- success: Logical indicating if operation succeeded

- data: data.table with downloaded data (or NULL on failure)

- exit_code: Integer exit code (0=success, 1=error, 2=timeout)

- message: Character message describing result

- md5: Character MD5 checksum of data (or NA if not computed)

- is_timeout: Logical indicating if failure was due to timeout

- timestamp: POSIXct timestamp when result was created

## Details

Standard return structure for download operations providing consistent
success/failure information with exit codes.
