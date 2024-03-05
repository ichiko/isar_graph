# isar_graph

Isar の定義から mermaid を出力する。

Isar の annotation は型チェックしておらず、名前の先頭が collection/embedded で判別している。

## install

https://zenn.dev/noboru_i/articles/ea02828f33deaa を参考にするとよさそう

## how to use

```sh
$ fvm dart run isar_graph path/to/folder [-ae]
```

flags:

- a: show all fields. default show only indexed fields or IsarLink also IsarLink's type is collection.
- e: show embedded objects. default show only collection class.
