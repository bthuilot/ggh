module Git = Ggh.Git

(* let gitScopePP fmt scope = Format.fprintf fmt "%s" (Git.scope_to_string scope) *)

(* let test_repo_config_get () = *)
(*   let mock_keygroup = "gghtest" *)
(*   and mock_keysub = "test-repo-config-get" *)
(*   and mock_val = "testing123456790" in *)
(*   Git_mock.write_repo_config (mock_keygroup ^ "." ^ mock_keysub) mock_val; *)
(*   let result = Git.get_config_values ~group:mock_keygroup mock_keysub in *)
(*   (\* before running test, clear entry *\) *)
(*   Git_mock.clear_values [ mock_keygroup ^ "." ^ mock_keysub ]; *)

(*   Alcotest.(check (testable gitScopePP ( = )) string))) *)
(*     "failed to get git config value" *)
(*     [mock_val] *)
(*     result *)

(* let test_repo_config_get_multiple () = *)
(*   let mock_keygroup = "gghtest" *)
(*   and mock_keysub = "test-repo-config-get-multiple" *)
(*   and mock_val_repo = "testing123456790" *)
(*   and mock_val_global = "1234567890testing" in *)
(*   let mock_key = mock_keygroup ^ "." ^ mock_keysub in *)
(*   Git_mock.write_repo_config mock_key mock_val_repo; *)
(*   Git_mock.write_global_config mock_key mock_val_global; *)
(*   let result = Git.get_config_values ~group:mock_keygroup mock_keysub in *)
(*   (\* before running test, clear entry *\) *)
(*   Git_mock.clear_values [ mock_key ]; *)

(*   Alcotest.(check (option (list (pair (testable gitScopePP ( = )) string)))) *)
(*     "failed to get git config value" *)
(*     (Some [ (Git.Local, mock_val_repo); (Git.Global, mock_val_global) ]) *)
(*     result *)

let () =
  Alcotest.run "git.ml"
    [
      ( "config",
        [ (* Alcotest.test_case "get config value" `Slow test_repo_config_get; *)
          (* Alcotest.test_case "get config values" `Slow *)
          (* test_repo_config_get_multiple; *) ] );
    ]
