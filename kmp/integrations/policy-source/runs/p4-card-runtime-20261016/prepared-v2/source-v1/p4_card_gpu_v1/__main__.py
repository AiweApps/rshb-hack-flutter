"""Root-operated P4: model-free describe/preflight, or one serial parent graph."""
import json
import os
import sys


def main():
    if sys.argv[1:] not in (['describe'], ['preflight'], ['serve']):
        raise SystemExit(__doc__)
    from .factory import factory, model_free
    if sys.argv[1] != 'serve':
        print(json.dumps(model_free(sys.argv[1]), ensure_ascii=False), flush=True)
        return
    pipeline, app_factory, receipt = factory()
    import uvicorn
    host = os.environ.get('WINE_P4_HOST', '127.0.0.1')
    port = int(os.environ.get('WINE_P4_PORT', '8383'))
    if host not in ('127.0.0.1', '::1') or port != 8383:
        raise RuntimeError('P4 must use the root-reviewed serial wine8383 endpoint')
    print(json.dumps(receipt, ensure_ascii=False), flush=True)
    uvicorn.run(app_factory(pipeline), host=host, port=port, workers=1,
                access_log=False, proxy_headers=False, server_header=False)


if __name__ == '__main__':
    main()
