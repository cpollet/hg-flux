"""hg-flux is an extension to help implementing a standard branching model
"""

from mercurial import cmdutil
from mercurial.i18n import _
from mercurial import commands
from mercurial.merge import nullid
from mercurial.merge import error

cmdtable = {}
command = cmdutil.command(cmdtable)


@command('flux-open', [
    ('c', 'commit', False, _('auto commit after creating branch'))
], _('[options] <name>'))
def open(ui, repo, name=None, **opts):
    """opens a new feature/bugfix branch

<name> is the name of the feature branch. For instance: bug tracker task ID
"""
    if not repo_is_clean(ui, repo):
        ui.write("You have uncommitted changes. Please commit before proceeding.\n")
        commands.status(ui, repo)
        return

    ui.write("$ hg branches :: contains {}?\n".format(name))
    for branch in branches(repo):
        if branch[0] == name:
            ui.write("Branch {} already exists, not creating new one.\n".format(name))
            return

    ui.write("$ hg update {}\n".format("stable"))

    commands.update(ui, repo, None, 'stable', False, None, True)
    ui.write("$ hg branch {}\n".format("name"))
    commands.branch(ui, repo, name)

    if opts.get("commit"):
        ui.write("$ hg commit -m \"Created branch '{}'\"\n".format(name))
        commands.commit(ui, repo, ".", message="Created branch '{}'".format(name))
        ui.write("committed new branch {}.\n".format(name))


def branches(repo):
    if "iterbranches" in dir(repo.branchmap()):  # only available since mercurial 2.9
        return [(branch[0], not branch[3]) for branch in repo.branchmap().iterbranches()]

    branches = []
    for tag, heads in repo.branchmap().iteritems():
        isopen = False
        for h in reversed(heads):
            ctx = repo[h]
            isopen = not ctx.closesbranch()
            if isopen:
                break
        branches.append((tag, isopen))
    return branches


def repo_is_clean(ui, repo):
    ui.write("$ hg status :: returns 1+ lines?\n")
    statuses = repo.status()
    for status in statuses:
        if len(status) > 0:
            return False
    return True


@command('flux-close', [], _('<name>'))
def close(ui, repo, name=None):
    """closes an existing feature/bugfix branch, ie. merge it to default branch

<name> is the name of the branch to close
"""
    if not repo_is_clean(ui, repo):
        ui.write(_("uncommitted changes, please commit before proceeding.\n"))
        commands.status(ui, repo)
        return

    merge_and_commit(ui, repo, name, "stable")
    ui.write("$ hg commit --close-branch -m \"Closed branch '{}'\"\n".format(name))
    commands.commit(ui, repo, ".", close_branch=True, message="Closed branch '{}'".format(name))
    merge_and_commit(ui, repo, "default", name)


def merge_and_commit(ui, repo, node_dst, node_src):
    ui.write("$ hg up {}\n".format(node_dst))
    commands.update(ui, repo, None, node_dst, False, None, True)

    if src_branch_is_not_ancestor(repo, node_src):
        ui.write("$ hg merge {}\n".format(node_src))
        conflicts = commands.merge(ui, repo, node_src)
        if conflicts:
            raise error.Abort(_("unable to auto-merge {} to {}, please merge manually and retry\n"
                                .format(node_src, node_dst)))
        ui.write("$ hg commit -m \"Merged branch '{}' to '{}'\"\n".format(node_src, node_dst))
        commands.commit(ui, repo, message="Merged branch '{}' to '{}'".format(node_src, node_dst))

    return False


def src_branch_is_not_ancestor(repo, node):
    """inspiration from merge.py, update() function"""
    p1 = repo[None].parents()[0]
    p2 = repo[node]

    if "commonancestorsheads" in dir(repo.changelog):  # from mercurial 3.0
        if repo.ui.configlist('merge', 'preferancestor', ['*']) == ['*']:
            cahs = repo.changelog.commonancestorsheads(p1.node(), p2.node())
            pa = [repo[anc] for anc in (sorted(cahs) or [nullid])]
        else:
            pa = [p1.ancestor(p2, warn=True)]

    else:
        pa = [p1.ancestor(p2)]

    return pa[0] != p2


@command('flux-prepare', [], _('<name>'))
def prepare(ui, repo, name=None):
    """adds a feature/bugfix/branch to stable

<name> the name of the branch to add
"""
    if not repo_is_clean(ui, repo):
        ui.write(_("uncommitted changes, please commit before proceeding.\n"))
        commands.status(ui, repo)
        return

    # todo: check if branch is closed!

    merge_and_commit(ui, repo, 'stable', name)


@command('flux-finish', [], _('<name>'))
def finish(ui, repo):
    """terminates a release by merging the stable branch to all open branches"""
    if not repo_is_clean(ui, repo):
        ui.write(_("uncommitted changes, please commit before proceeding.\n"))
        commands.status(ui, repo)
        return

    ui.write("$ hg branches :: get all open branches\n")
    for name, is_open in branches(repo):
        if name != 'stable' and is_open:
            merge_and_commit(ui, repo, name, 'stable')
