import re

from typing import List
from kittens.tui.handler import result_handler
from kitty.boss import Boss

VIM_PROCESS_NAME = 'n?vim'

def main(args: List[str]) -> str:
    pass

def is_window_vim(window):
    fp = window.child.foreground_processes
    return any(re.search(
        VIM_PROCESS_NAME,
        p['cmdline'][0] if len(p['cmdline']) else '',
        re.I
    ) for p in fp)


@result_handler(no_ui=True)
def handle_result(
    args: List[str],
    answer: str,
    target_window_id: int,
    boss: Boss
) -> None:
    window = boss.window_id_map.get(target_window_id)
    tab = boss.active_tab

    if window is None:
        return
    if tab is None:
        return

    if is_window_vim(window):
        if len(tab.windows) == 1:
            # make sure that we are in fat layout before launching new window
            # otherwise the new window might be launched in stack layout
            boss.call_remote_control(window, ("goto-layout", "--match=state:focused", "fat"))
            new_window = boss.call_remote_control(None, ("launch", "--type=window", "--cwd=current", "--title=current"))
        elif tab.current_layout.name == "stack":
            boss.call_remote_control(window, ("goto-layout", "--match=state:focused", "fat"))
            # we want to focus the terminal window
            boss.call_remote_control(window, ("focus-window", "--match=neighbor:bottom"))
        elif tab.current_layout.name == "fat":
            boss.call_remote_control(window, ("goto-layout", "--match=state:focused", "stack"))

        return


    # the current window is not nvim. so we are in a terminal or something else
    # first check and see if there is nvim somewhere
    nvim_window = next((w for w in tab.windows if is_window_vim(w)), None)
    if not nvim_window:
        # there is no nvim window in the current tab, exit
        return
    elif tab.current_layout.name == "stack":
        # there is one but but it is not focused and we are in stack. unstack and switch to nvim
        boss.call_remote_control(window, ("focus-window", f"--match=id:{nvim_window.id}"))
        boss.call_remote_control(window, ("goto-layout", "--match=state:focused", "fat"))
    else:
        # there is one but it is not focused and we are in the fat layout, let's focus it and switch to stack
        boss.call_remote_control(window, ("focus-window", f"--match=id:{nvim_window.id}"))
        boss.call_remote_control(window, ("goto-layout", "--match=state:focused", "stack"))
