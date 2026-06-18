#!/usr/bin/env python3
# Render the calm-mode statusline as PNG (text-only, terminal style).
from PIL import Image, ImageFont, ImageDraw
MONO="/System/Library/Fonts/SFNSMono.ttf"
FS=38; PAD_X,PAD_Y=60,50; LINE_GAP=18; BG=(13,16,23)
font=ImageFont.truetype(MONO,FS)
C={"gray":(155,160,170),"118":(135,255,0),"be":(42,47,58),
   "110":(135,175,215),"108":(135,175,135)}
line1=[("text","Context left","gray"),("sp"," ",None),
       ("text","████████","118"),("text","░░░░░░","be"),("sp"," ",None),
       ("text","58%","118")]
line2=[("text","~/projects/kaoshipan","110"),("sp"," ",None),
       ("text","git:(main*)","108")]
def measure(t):
    w=0;ch=font.getlength("M")
    for k,c,_ in t: w+= ch*len(c) if k=="sp" else font.getlength(c)
    return w
asc,desc=font.getmetrics();LH=asc+desc
W=int(max(measure(line1),measure(line2)))+PAD_X*2
H=PAD_Y*2+LH*2+LINE_GAP
img=Image.new("RGBA",(W,H),BG+(255,));d=ImageDraw.Draw(img)
def render(t,y):
    x=PAD_X;ch=font.getlength("M")
    for k,c,ck in t:
        if k=="sp": x+=ch*len(c)
        else: d.text((x,y),c,font=font,fill=C[ck]);x+=font.getlength(c)
render(line1,PAD_Y);render(line2,PAD_Y+LH+LINE_GAP)
out="/Users/a1234/.claude/skills/statusline-kit/preview-calm.png"
img.convert("RGB").save(out);print("saved",out,img.size)
