


/// Class to bundle input and output for an interpreter for easier communication
/// between inference isolate and main isolate.
class IsolateData {
  
  /// Inpute for the interpreter in the isolate
  dynamic input;
  /// Inpute for the interpreter in the isolate
  dynamic output;

  IsolateData(
    {
      this.input,
      this.output
    }
  );

}