from PIL import Image, ImageDraw
import json, sys
T=0.6  # texture scale vs. the source art
A=json.load(open('anchors_auto.json'))
A.update(json.load(open('anchors_fix.json')) if __import__('os').path.exists('anchors_fix.json') else {})
ORDER={
 'valkyrie':['valkyrie_%d'%i for i in range(12)],
 'berserker':['berserker_'+n for n in ['idle','walk1','walk2','walk3','walk4','jump','fall','hurt',
   'attack_neutral','attack_side','attack_down','rage1','rage2']],
}
out={}
for legend,names in ORDER.items():
    ims={n:Image.open('raw_%s.png'%n) for n in names}
    L=max(A[n][0] for n in names); R=max(ims[n].width-A[n][0] for n in names)
    U=max(A[n][1] for n in names); D=max(ims[n].height-A[n][1] for n in names)
    cw,ch=L+R+4,U+D+4
    sheet=Image.new('RGBA',(cw*len(names),ch),(0,0,0,0))
    for i,n in enumerate(names):
        sheet.alpha_composite(ims[n],(i*cw+L+2-A[n][0],U+2-A[n][1]))
    sw,sh=round(sheet.width*T/len(names))*len(names),round(sheet.height*T)
    sheet=sheet.resize((sw,sh),Image.LANCZOS)
    sheet.save('%s_sheet.png'%legend)
    cell=(sw//len(names),sh)
    anchor=((L+2)*T,(U+2)*T)
    out[legend]={'frames':len(names),'cell':cell,'anchor':[round(anchor[0],1),round(anchor[1],1)]}
    # preview: all frames on one ground line
    pv=Image.new('RGBA',(cell[0]*len(names),cell[1]+20),(70,150,90,255)); d=ImageDraw.Draw(pv)
    pv.alpha_composite(sheet,(0,0))
    for i in range(len(names)):
        x=i*cell[0]+anchor[0]; d.line((x,0,x,cell[1]),fill=(255,255,0)); d.text((i*cell[0]+3,cell[1]+4),names[i].split('_',1)[1],fill=(255,255,255))
    d.line((0,anchor[1],pv.width,anchor[1]),fill=(255,0,255))
    pv.convert('RGB').save('preview_%s.png'%legend)
json.dump(out,open('sheets.json','w'),indent=1); print(out)
