{ lib }:

let
  inherit (builtins)
    readDir
    ;

  inherit (lib.attrsets)
    mapAttrs
    mapAttrsToList
    mergeAttrsList
    ;

in
rec {
  # Package paths for a directory, this is intened to be used with
  # builtins.readDir, in which the contents can use this function to map over
  # the results
  # Type: Path -> _ -> String -> AttrsOf Path
  mkNamesForDirectory = baseDirectory: _: type:
    if type != "directory" then
      # Ignore files, and only assume that directories will be imported by default
      { }
    else
      mapAttrs
        (name: _: baseDirectory + "/${name}")
        (readDir (baseDirectory + "/"));


  # Type: Path -> Overlay
  mkAutoCalledPackageDir = baseDirectory:
    let
      namesForShard = mkNamesForDirctory baseDirectory;
      # This is defined up here in order to allow reuse of the value (it's kind of expensive to compute)
      # if the overlay has to be applied multiple times
      packageFiles = mergeAttrsList (mapAttrsToList namesForShard (readDir baseDirectory));
    in
  # TODO: Consider optimising this using `builtins.deepSeq packageFiles`,
  # which could free up the above thunks and reduce GC times.
  # Currently this would be hard to measure until we have more packages
  # and ideally https://github.com/NixOS/nix/pull/8895
  self: super:
  {
    # Used to verify call by-name usage
    _internalCallByNamePackageFile = file: self.callPackage file { };
  }
  // mapAttrs
    (name: value: self._internalCallByNamePackageFile value)
    packageFiles;
}


