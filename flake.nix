{
  description = "My home configuration";

  outputs = _: {
    homeModules.default = ./home;
  };
}
