{
  description = "Shardul's Home Manager configuration";

  outputs = _: {
    homeModules.default = ./home;
  };
}
