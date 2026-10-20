"""Declared import-only adapters for the bundled, inference-only Python rules.

Original source bytes stay intact for provenance. Runtime ranking functions are
AST-identical. Training-only SciPy imports move into their original fit function;
no replacement optimizer, fake package or changed prediction is supplied.
"""
import ast
from copy import deepcopy
import hashlib
import importlib.abc
import importlib.util
from pathlib import Path


ADAPTERS = {
    'rshb_vine.ranker_dataset_v1.model': {
        'path': 'rshb_vine/ranker_dataset_v1/model.py',
        'source_sha256': 'fe2c42e171f19b63d6f00a42d4ab322ad5ef3e7eae7be9595e39f736ee0af55e',
        'imports': ('from scipy.optimize import minimize', 'from scipy.special import logsumexp, softmax'),
        'destination': 'fit_once',
    },
    'rshb_vine.bottle_rescue': {
        'path': 'rshb_vine/bottle_rescue.py',
        'source_sha256': 'e095596c32228552d022c50a70753b876a7130436e15a15a967432709811c33d',
        'imports': ('import torch',),
        'destination': 'LowBottleDetector.detect',
    },
    'scripts.run_label_specialist_consensus': {
        'path': 'scripts/run_label_specialist_consensus.py',
        'source_sha256': '958481ab6417e6a9979a54d5c47aab7ce26f69ce2984f4ebfae6f4b1031c50fa',
        'imports': ('from rshb_vine.encoder_artifact import load_encoder',),
        'destination': 'GuardedConsensus.__init__',
    },
}


def inference_source(data, contract):
    if hashlib.sha256(data).hexdigest() != contract['source_sha256']:
        raise ImportError('Mobile inference adapter source pin changed: ' + contract['path'])
    tree = ast.parse(data)
    original = deepcopy(tree)
    moved = [node for node in tree.body if isinstance(node, (ast.Import, ast.ImportFrom)) and ast.unparse(node) in contract['imports']]
    if len(moved) != len(contract['imports']):
        raise ImportError('Mobile training-import adapter is ambiguous')
    def destination(module):
        scope = module
        for part in contract['destination'].split('.'):
            found = [node for node in scope.body if isinstance(node, (ast.FunctionDef, ast.ClassDef)) and node.name == part]
            if len(found) != 1: raise ImportError('Mobile deferred-import destination is ambiguous')
            scope = found[0]
        if not isinstance(scope, ast.FunctionDef): raise ImportError('Deferred imports require a function body')
        return scope
    target = destination(tree)
    tree.body = [node for node in tree.body if node not in moved]
    target.body[:0] = moved
    # Remove only the declared inserted import statements in a verification
    # copy. Every other statement, including all constructor/model math and all
    # recognise/rerank bodies, must match the original AST exactly.
    verification = deepcopy(tree)
    destination(verification).body = destination(verification).body[len(moved):]
    original.body = [node for node in original.body if not (
        isinstance(node, (ast.Import, ast.ImportFrom)) and ast.unparse(node) in contract['imports'])]
    if ast.dump(verification, include_attributes=False) != ast.dump(original, include_attributes=False):
        raise ImportError('Mobile adapter changed source beyond declared import movement')
    return ast.fix_missing_locations(tree)


class InferenceImports(importlib.abc.MetaPathFinder):
    def __init__(self, root):
        self.root = Path(root)
        self.applied = []

    def find_spec(self, fullname, path=None, target=None):
        if fullname.split('.')[0] in ('torch', 'paddle', 'paddlex', 'transformers', 'sklearn', 'scipy'):
            raise ImportError('Training/model package is forbidden in the mobile policy: ' + fullname)
        contract = ADAPTERS.get(fullname)
        if contract is None:
            return None
        owner = self
        class Loader(importlib.abc.Loader):
            def create_module(self, spec): return None
            def exec_module(self, module):
                filename = owner.root / contract['path']
                data = filename.read_bytes()
                tree = inference_source(data, contract)
                module.__file__ = str(filename)
                exec(compile(tree, str(filename), 'exec'), module.__dict__)
                owner.applied.append(dict(module=fullname, source_sha256=contract['source_sha256'],
                    adapter='deferred imports moved into ' + contract['destination'],
                    non_import_statements_AST_identical=True))
        return importlib.util.spec_from_loader(fullname, Loader(), origin=str(self.root / contract['path']))
