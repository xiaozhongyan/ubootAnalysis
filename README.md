# ubootAnalysis
# version =0.1
# 本项目是 服务机器人实时嵌入式操作系统 操作系统启动前期代码UBOOT 顶层makefile文件解析。
# 
# 注意：ubootmakefile文件不会作为更新文件，现当作原文件使用
#      现指定ubootmakefile.mk为更新的makefile文件。

# 博客中相关注释：
# https://zhuanlan.zhihu.com/p/35844089
# https://zhuanlan.zhihu.com/p/35841260
# https://zhuanlan.zhihu.com/p/35786863
# https://zhuanlan.zhihu.com/p/35783584
# https://blog.csdn.net/guyongqiangx/article/details/52565493
# 
# 文件：文件名后缀与文件类型无关，只为了LINUX下阅读方便 
# ubootmakefile.mk 
#                   顶层makefile文件注释
# makeOutput.sh
#                   通过执行make efi-x86_config配置生成的.config
#                   然后执行make 生成的代码
# ubootmakefile 
#                   第一版本的注释文件，现在弃用，作为ubootmakefile.mk的原参考文件
# Uboot系统构建.docx
#                   系统架构文档

##文件类型注释：
##  elf格式: https://blog.csdn.net/gx19862005/article/details/53350032
##          https://blog.csdn.net/feglass/article/details/51469511
##  
##  srec格式：
##  
##  hex格式：
## 
##  img格式：
##
##  bin/hex/elf/srec/img 区别 https://blog.csdn.net/chun_1959/article/details/43731937
