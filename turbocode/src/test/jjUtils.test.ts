import * as assert from "assert";
import {
  execJj,
  parseLogOutput,
  getLogCommand,
  CommitInfo,
} from "../jjUtils";
import { execFile } from "child_process";
import { promisify } from "util";
import {
  createTestRepo,
  cleanupTestRepo,
  getTestRepoPath,
  commitFile,
  commitFiles,
  createBookmark,
  deleteBookmark,
  newCommit,
  isJjAvailable,
  getLogWithTemplate,
} from "./testHelpers";

const execFileAsync = promisify(execFile);

describe("JJ Command Execution Tests", () => {
  beforeEach(() => {
    cleanupTestRepo(getTestRepoPath("parsing-test-repo"));
  });

  describe("execJj()", () => {
    it("should use correct working directory", async () => {
      jest.setTimeout(5000);

      const cwd = process.cwd();
      const result = await execJj(["--version"], cwd);
      assert.ok(result.length > 0, "Should return version output");
    });

    it("should handle errors correctly (shows stderr in error message)", async () => {
      jest.setTimeout(5000);

      const cwd = process.cwd();
      try {
        await execJj(["nonexistent-command-that-fails"], cwd);
        assert.fail("Should have thrown an error");
      } catch (error: any) {
        assert.ok(error.message, "Error should have a message");
        assert.ok(
          error.message.includes("JJ command failed"),
          "Error message should indicate JJ command failure"
        );
      }
    });

    it("should use provided cwd when specified", async () => {
      jest.setTimeout(5000);

      const cwd = process.cwd();
      const result = await execJj(["--version"], cwd);
      assert.ok(result.length > 0, "Should return version output");
    });
  });

});

describe("Log Output Parsing Tests", () => {
  let testRepo: string | null = null;
  let initialCommitId: string | null = null;

  beforeAll(async () => {
    jest.setTimeout(10000);

    if (!(await isJjAvailable())) {
      throw new Error("JJ is not available - skipping tests that require JJ");
    }

    const repoInfo = await createTestRepo("parsing-test-repo");
    testRepo = repoInfo.repoPath;
    initialCommitId = repoInfo.initialCommitId;
  });

  afterAll(() => {
    if (testRepo) {
      cleanupTestRepo(testRepo);
    }
  });

  describe("parseLogOutput()", () => {
    it("should parse single commit line with all fields", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      const bookmarkName = "test-bookmark-" + Date.now();
      const commitId = await commitFile(
        testRepo!,
        "file1.txt",
        "content",
        "Purge gcloud cached credentials"
      );

      await createBookmark(testRepo!, bookmarkName, commitId);

      const output = await getLogWithTemplate(testRepo!, 10);
      const commits = parseLogOutput(output);

      // Commit IDs in log output are 8 chars (short format), so compare with first 8 chars
      const shortCommitId = commitId.substring(0, 8);
      const commit = commits.find(
        (c) => c.commitId === shortCommitId || commitId.startsWith(c.commitId)
      );
      assert.ok(commit, "Should find the commit");
      // Commit ID from parser should match the short format (8 chars)
      assert.ok(
        commit!.commitId.length >= 8 && commitId.startsWith(commit!.commitId),
        "Should extract commit ID"
      );
      assert.ok(commit!.changeId.length > 0, "Should extract change ID");
      assert.ok(
        commit!.bookmarks.includes(bookmarkName),
        "Should extract bookmark"
      );
      assert.strictEqual(
        commit!.summary,
        "Purge gcloud cached credentials",
        "Should extract summary"
      );

      await deleteBookmark(testRepo!, bookmarkName);
    });

    it("should parse commit line with no bookmarks", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      const commitId = await commitFile(
        testRepo!,
        "file2.txt",
        "content",
        "Purge gcloud cached credentials"
      );

      const output = await getLogWithTemplate(testRepo!, 10);
      const commits = parseLogOutput(output);

      // Commit IDs in log output are 8 chars (short format), so compare with first 8 chars
      const shortCommitId = commitId.substring(0, 8);
      const commit = commits.find(
        (c) => c.commitId === shortCommitId || commitId.startsWith(c.commitId)
      );
      assert.ok(commit, "Should find the commit");
      // Commit ID from parser should match the short format (8 chars)
      assert.ok(
        commit!.commitId.length >= 8 && commitId.startsWith(commit!.commitId),
        "Should extract commit ID"
      );
      assert.ok(commit!.changeId.length > 0, "Should extract change ID");
      assert.deepStrictEqual(
        commit!.bookmarks,
        [],
        "Should have empty bookmarks"
      );
      assert.strictEqual(
        commit!.summary,
        "Purge gcloud cached credentials",
        "Should extract summary"
      );
    });

    it("should parse commit line with multiple bookmarks (space-separated)", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      const commitId = await commitFile(
        testRepo!,
        "file3.txt",
        "content",
        "Merge pull request #1240"
      );

      const bookmark1 = "test-branch-1-" + Date.now();
      const bookmark2 = "test-branch-2-" + Date.now();
      const bookmark3 = "test-branch-3-" + Date.now();

      await createBookmark(testRepo!, bookmark1, commitId);
      await createBookmark(testRepo!, bookmark2, commitId);
      await createBookmark(testRepo!, bookmark3, commitId);

      const output = await getLogWithTemplate(testRepo!, 10);
      const commits = parseLogOutput(output);

      // Commit IDs in log output are 8 chars (short format), so compare with first 8 chars
      const shortCommitId = commitId.substring(0, 8);
      const commit = commits.find(
        (c) => c.commitId === shortCommitId || commitId.startsWith(c.commitId)
      );
      assert.ok(commit, "Should find the commit");
      // Commit ID from parser should match the short format (8 chars)
      assert.ok(
        commit!.commitId.length >= 8 && commitId.startsWith(commit!.commitId),
        "Should extract commit ID"
      );
      assert.ok(commit!.changeId.length > 0, "Should extract change ID");
      assert.ok(
        commit!.bookmarks.length >= 3,
        "Should extract multiple bookmarks"
      );
      assert.ok(
        commit!.bookmarks.includes(bookmark1),
        "Should include bookmark1"
      );
      assert.ok(
        commit!.bookmarks.includes(bookmark2),
        "Should include bookmark2"
      );
      assert.ok(
        commit!.bookmarks.includes(bookmark3),
        "Should include bookmark3"
      );
      assert.ok(
        commit!.summary.includes("Merge pull request"),
        "Should extract summary"
      );

      await deleteBookmark(testRepo!, bookmark1);
      await deleteBookmark(testRepo!, bookmark2);
      await deleteBookmark(testRepo!, bookmark3);
    });

    it("should parse commit line with multi-word summary", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      const summary = "This is a multi word summary with spaces";
      const commitId = await commitFile(
        testRepo!,
        "file4.txt",
        "content",
        summary
      );

      const output = await getLogWithTemplate(testRepo!, 10);
      const commits = parseLogOutput(output);

      // Commit IDs in log output are 8 chars (short format), so compare with first 8 chars
      const shortCommitId = commitId.substring(0, 8);
      const commit = commits.find(
        (c) => c.commitId === shortCommitId || commitId.startsWith(c.commitId)
      );
      assert.ok(commit, "Should find the commit");
      assert.strictEqual(
        commit!.summary,
        summary,
        "Should extract full summary"
      );
    });

    it("should parse commit line with graph characters before commit ID", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      await commitFile(testRepo!, "file5.txt", "content", "First commit");
      await commitFile(testRepo!, "file6.txt", "content", "Second commit");

      const output = await getLogWithTemplate(testRepo!, 10);
      const commits = parseLogOutput(output);

      assert.ok(commits.length >= 2, "Should parse multiple commits");
      for (const commit of commits) {
        // Commit IDs are 8 chars in short format, but can be 8-12 chars
        assert.ok(
          commit.commitId.length >= 8 && commit.commitId.length <= 12,
          "Should extract commit ID (8-12 chars)"
        );
        assert.ok(commit.changeId.length > 0, "Should extract change ID");
      }
    });

    it("should handle lines without commits (graph-only lines)", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      await commitFile(testRepo!, "file7.txt", "content", "Test commit");

      const output = await getLogWithTemplate(testRepo!, 10);

      const lines = output.split("\n");
      const graphOnlyLines = lines
        .filter((line) => {
          // Filter out lines that contain commit IDs (8 or 12 hex chars) or change IDs (8-12 alphanumeric)
          return !line.match(/\b[a-f0-9]{8,12}\b/i) && !line.match(/\b[a-z0-9]{8,12}\b/);
        })
        .join("\n");

      const commits = parseLogOutput(graphOnlyLines);
      assert.strictEqual(
        commits.length,
        0,
        "Should not parse commits from graph-only lines"
      );
    });

    it('should handle "elided revisions" lines', async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      await commitFiles(testRepo!, [
        { path: "file-elide-0.txt", content: "content", message: "Commit 0" },
        { path: "file-elide-1.txt", content: "content", message: "Commit 1" },
        { path: "file-elide-2.txt", content: "content", message: "Commit 2" },
        { path: "file-elide-3.txt", content: "content", message: "Commit 3" },
        { path: "file-elide-4.txt", content: "content", message: "Commit 4" },
      ]);

      const output = await getLogWithTemplate(testRepo!, 100);

      const elidedLine = "│ ~  (elided revisions)";
      const commits = parseLogOutput(elidedLine);
      assert.strictEqual(
        commits.length,
        0,
        "Should not parse commits from elided revisions line"
      );
    });

    it("should extract commit ID correctly from various graph formats", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      const commit1Id = await commitFile(
        testRepo!,
        "file-graph1.txt",
        "content",
        "Commit 1"
      );

      const branchCommitId = await newCommit(testRepo!, "Commit 2");
      const commit2Id = await commitFile(
        testRepo!,
        "file-graph2.txt",
        "content",
        "Commit 2"
      );

      const output = await getLogWithTemplate(testRepo!, 10);
      const commits = parseLogOutput(output);

      // Commit IDs in log output are 8 chars (short format), so compare with first 8 chars
      const shortCommit1Id = commit1Id.substring(0, 8);
      const shortCommit2Id = commit2Id.substring(0, 8);
      const foundCommit1 = commits.find(
        (c) => c.commitId === shortCommit1Id || commit1Id.startsWith(c.commitId)
      );
      const foundCommit2 = commits.find(
        (c) => c.commitId === shortCommit2Id || commit2Id.startsWith(c.commitId)
      );

      assert.ok(foundCommit1, "Should find first commit");
      assert.ok(foundCommit2, "Should find second commit");
      assert.ok(
        foundCommit1!.commitId.length >= 8 && commit1Id.startsWith(foundCommit1!.commitId),
        "Should extract correct commit ID"
      );
      assert.ok(
        foundCommit2!.commitId.length >= 8 && commit2Id.startsWith(foundCommit2!.commitId),
        "Should extract correct commit ID"
      );
    });

    it("should parse sample JJ log output correctly", async () => {
      jest.setTimeout(10000);
      if (!testRepo) {
        throw new Error("Test repo not initialized");
      }

      const commit1Id = await commitFile(
        testRepo!,
        "file-sample1.txt",
        "content",
        "Purge gcloud cached credentials"
      );
      const bookmark1 = "push-test-" + Date.now();
      await createBookmark(testRepo!, bookmark1, commit1Id);

      const commit2Id = await commitFile(
        testRepo!,
        "file-sample2.txt",
        "content",
        "Merge pull request #1240"
      );
      const bookmark2a = "branch-a-" + Date.now();
      const bookmark2b = "branch-b-" + Date.now();
      await createBookmark(testRepo!, bookmark2a, commit2Id);
      await createBookmark(testRepo!, bookmark2b, commit2Id);

      const output = await getLogWithTemplate(testRepo!, 10);
      const commits = parseLogOutput(output);

      assert.ok(
        commits.length >= 2,
        `Should parse at least 2 commits, got ${commits.length}`
      );

      // Commit IDs in log output are 8 chars (short format), so compare with first 8 chars
      const shortCommit1Id = commit1Id.substring(0, 8);
      const shortCommit2Id = commit2Id.substring(0, 8);
      const firstCommit = commits.find(
        (c) => c.commitId === shortCommit1Id || commit1Id.startsWith(c.commitId)
      );
      assert.ok(firstCommit, "Should find first commit");
      assert.ok(
        firstCommit!.bookmarks.includes(bookmark1),
        "First commit should have bookmark"
      );
      assert.strictEqual(
        firstCommit!.summary,
        "Purge gcloud cached credentials",
        "First commit should have correct summary"
      );

      const secondCommit = commits.find(
        (c) => c.commitId === shortCommit2Id || commit2Id.startsWith(c.commitId)
      );
      assert.ok(secondCommit, "Should find second commit");
      assert.ok(
        secondCommit!.bookmarks.length >= 2,
        "Second commit should have multiple bookmarks"
      );
      assert.ok(
        secondCommit!.bookmarks.includes(bookmark2a),
        "Should include bookmark2a"
      );
      assert.ok(
        secondCommit!.bookmarks.includes(bookmark2b),
        "Should include bookmark2b"
      );
      assert.ok(
        secondCommit!.summary.includes("Merge pull request"),
        "Should extract summary"
      );

      await deleteBookmark(testRepo!, bookmark1);
      await deleteBookmark(testRepo!, bookmark2a);
      await deleteBookmark(testRepo!, bookmark2b);
    });

    it("should handle empty input", () => {
      const commits = parseLogOutput("");
      assert.strictEqual(
        commits.length,
        0,
        "Should return empty array for empty input"
      );
    });

    it("should handle input with only whitespace", () => {
      const commits = parseLogOutput("   \n  \n  ");
      assert.strictEqual(
        commits.length,
        0,
        "Should return empty array for whitespace-only input"
      );
    });

    it("should parse multiple commits with complex graph structure", () => {
      const output = `@  ppnyxztp shardul@baral.ca 2025-11-05 13:42:18 push-ppnyxztprttn 26619042
│  Purge gcloud cached credentials
│ ◆  zlystqzl kirin@gadget.dev 2025-11-05 12:12:09 cursor/include-environment-id-in-typedocs-error-logs-57fe@origin cursor/include-environment-id-in-typedocs-error-logs-a053@origin cursor/include-environment-id-in-typedocs-error-logs-cba6@origin main 3cc79f85
╭─┤  (empty) Merge pull request #1240 from gadget-inc/kirin/scaledown_core_control_plane_15
│ ~  (elided revisions)
├─╯
◆    zlqrvkxt kirin@gadget.dev 2025-11-04 17:37:03 git_head() e4e326bc
├─╮  (empty) Merge pull request #1235 from gadget-inc/kirin/GGT-9234/use_alloydb_for_dateilager_pgbouncers
│ ◆  vpsvzlxn kirin@gadget.dev 2025-11-04 10:17:36 fd93c374
│ │  use alloydb as destination database for dateilager
│ ~
│
◆  rzqsqvny harry.brundage@gmail.com 2025-11-04 16:26:29 4108eb0c
│  Raise gubernator presleep duration to see if errors in service discovery go away
~`;

      const commits = parseLogOutput(output);
      
      assert.strictEqual(commits.length, 5, "Should parse all 5 commits");
      
      // Verify first commit
      const firstCommit = commits.find(c => c.changeId === "ppnyxztprttn");
      assert.ok(firstCommit, "Should find first commit");
      assert.strictEqual(firstCommit!.commitId, "26619042", "First commit should have correct commit ID");
      assert.strictEqual(firstCommit!.summary, "Purge gcloud cached credentials", "First commit should have correct summary");
      
      // Verify second commit (the one with │ ◆ prefix that was being filtered)
      const secondCommit = commits.find(c => c.changeId === "zlystqzl");
      assert.ok(secondCommit, "Should find second commit with │ ◆ prefix");
      assert.strictEqual(secondCommit!.commitId, "3cc79f85", "Second commit should have correct commit ID");
      assert.ok(secondCommit!.bookmarks.includes("main"), "Second commit should have main bookmark");
      
      // Verify third commit
      const thirdCommit = commits.find(c => c.changeId === "zlqrvkxt");
      assert.ok(thirdCommit, "Should find third commit");
      assert.strictEqual(thirdCommit!.commitId, "e4e326bc", "Third commit should have correct commit ID");
      
      // Verify fourth commit (with │ ◆ prefix)
      const fourthCommit = commits.find(c => c.changeId === "vpsvzlxn");
      assert.ok(fourthCommit, "Should find fourth commit with │ ◆ prefix");
      assert.strictEqual(fourthCommit!.commitId, "fd93c374", "Fourth commit should have correct commit ID");
      assert.strictEqual(fourthCommit!.summary, "use alloydb as destination database for dateilager", "Fourth commit should have correct summary");
      
      // Verify fifth commit
      const fifthCommit = commits.find(c => c.changeId === "rzqsqvny");
      assert.ok(fifthCommit, "Should find fifth commit");
      assert.strictEqual(fifthCommit!.commitId, "4108eb0c", "Fifth commit should have correct commit ID");
    });

    it("should not filter out commits with various graph prefixes", () => {
      const testCases = [
        { prefix: "@  ", desc: "at symbol prefix" },
        { prefix: "◆  ", desc: "diamond prefix" },
        { prefix: "│ ◆  ", desc: "vertical bar + diamond prefix" },
        { prefix: "├─╮  ", desc: "merge graph prefix" },
        { prefix: "│ │  ", desc: "multiple vertical bars prefix" },
      ];

      for (const testCase of testCases) {
        const output = `${testCase.prefix}xyzkmnopqrst user@example.com 2025-11-05 12:00:00 main a1b2c3d4
│  Test commit message`;
        
        const commits = parseLogOutput(output);
        assert.strictEqual(
          commits.length,
          1,
          `Should parse commit with ${testCase.desc}`
        );
        assert.strictEqual(
          commits[0].changeId,
          "xyzkmnopqrst",
          `Should extract change ID with ${testCase.desc}`
        );
        assert.strictEqual(
          commits[0].commitId,
          "a1b2c3d4",
          `Should extract commit ID with ${testCase.desc}`
        );
      }
    });

    it("should handle commits with description lines correctly", () => {
      const output = `@  ppnyxztp shardul@baral.ca 2025-11-05 13:42:18 push-ppnyxztprttn 26619042
│  Purge gcloud cached credentials
│ ◆  zlystqzl kirin@gadget.dev 2025-11-05 12:12:09 main 3cc79f85
│  (empty) Merge pull request #1240`;

      const commits = parseLogOutput(output);
      
      assert.strictEqual(commits.length, 2, "Should parse both commits");
      
      const firstCommit = commits[0];
      assert.strictEqual(firstCommit.summary, "Purge gcloud cached credentials", "Should extract summary from description line");
      
      const secondCommit = commits[1];
      assert.strictEqual(secondCommit.summary, "(empty) Merge pull request #1240", "Should extract summary with (empty) prefix");
    });
  });

  describe("getLogCommand()", () => {
    it("should generate correct log command", () => {
      const args = getLogCommand(100);

      assert.ok(args.includes("log"), "Should include log command");
      assert.ok(args.includes("-n"), "Should include -n flag");
      assert.ok(args.includes("100"), "Should include count");
      assert.ok(args.includes("--color=never"), "Should include color flag");
      assert.ok(args.includes("-T"), "Should include template flag");
      assert.ok(args.includes("builtin_log_compact"), "Should use builtin_log_compact template");
    });

    it("should use default count when not specified", () => {
      const args = getLogCommand();
      const nIndex = args.indexOf("-n");
      assert.ok(nIndex >= 0, "Should include -n flag");
      assert.strictEqual(args[nIndex + 1], "100", "Should default to 100");
    });
  });
});
