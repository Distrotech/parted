#ifndef BFS_H
#define BFS_H

#ifndef blk_t
  typedef long long blk_t;
#endif

struct bfs_sb
{
        char magic[4];
        uint32_t start;
        uint32_t size;
        uint32_t sanity[4];
};

struct bfs_inode
{
        uint32_t i;
        uint32_t start;
        uint32_t end;
        uint32_t eof_off;
        uint32_t attr;
        uint32_t mode;
        uint32_t uid;
        uint32_t gid;
        uint32_t nlinks;
        uint32_t atime;
        uint32_t ctime;
        uint32_t reserved[4];
};

struct bfs_dirent
{
        uint16_t        i;
        uint8_t         name[14];
};

struct BfsSpecific
{
        struct bfs_sb   *sb;
        int             n_inodes;
        blk_t           data_start;
        long long       size;
};

#endif

