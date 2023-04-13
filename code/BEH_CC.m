%% Calculate Data
clear all; clc
datapath=('Y:\EEG_Data\PDDys\BEH\');
cd(datapath);

subjcount=0;        % 803 S1 B4 is a repeat of B1, and B1 was bad
for subno=[801:811,813:829];
    for session=1:2
        
        subjcount=subjcount+1;
        disp(['Subno: ',num2str(subno),'  Session: ',num2str(session)]); disp(' ');
        
        MEGA_ID(subjcount,:)=[subno,session];
        
        % TRAIN
        % each will have varied number of rows
        B1=load([num2str(subno),'_B1_Session',num2str(session),'_CC_train.mat']);
        B2=load([num2str(subno),'_B2_Session',num2str(session),'_CC_train.mat']);
        B3=load([num2str(subno),'_B3_Session',num2str(session),'_CC_train.mat']);
        B4=load([num2str(subno),'_B4_Session',num2str(session),'_CC_train.mat']);
        
        % ----- Columns are: -----
        %   1=data_block
        %   2=count
        % 3=type (1=A, 2=B, 3=C, 4=D)
        % 4=color (1=left, 2=right)
        % 5=congru (1=congru, 2=incongru)
        %   6=to be rewarded or not (?)
        %   7=response (1=resp, -1=noresp)
        %   8=selected_a_stim (1=yes, 0=no)  (I don't really know why this is here)
        %  9=RT
        % 10=acc (-1=tooslow, 0=incor, 1=cor)
        % 11=feedback (-3=error/tooslow, 0, 1)
        
        for bi=1:4
            PEslow{bi}=[];
        end
        for ai=1:4
            if     ai==1, data4display=B1.data_block; Block='1';
            elseif ai==2, data4display=B2.data_block; Block='2';
            elseif ai==3, data4display=B3.data_block; Block='3';
            elseif ai==4, data4display=B4.data_block; Block='4';
            end
            
            % Account for -3's
            slowcount=0; errcount=0; errrt=0; err_p_incong=0.01; % so 0 is no errors, 0.01 could be 1 congru error
            for bi=1:size(data4display,1)
                if data4display(bi,11)==-3 % if error/tooslow
                    if data4display(bi,10)==-1 % too slow
                        slowcount=slowcount+1;
                    elseif data4display(bi,10)==0 % error
                        errcount=errcount+1;
                        errrt=errrt + data4display(bi,9);
                        err_p_incong=err_p_incong + data4display(bi,5)-1;  % 1 is cong / 2 is incong
                    end
                end
            end
            errrt=errrt / errcount;
            err_p_incong=err_p_incong / errcount;
            if isinf(err_p_incong), err_p_incong=0; end
            
            if any(data4display(:,11)==-3)
                PEidx=[0;0+(data4display(:,11)==-3)];
                PEidx=PEidx(1:end-1);
                PEslow{ai}=data4display(logical(PEidx),9);
            end
            
            if ai==1,     FORMODEL_TRN{subjcount}=data4display;
            elseif ai==2, FORMODEL_TRN{subjcount}=[FORMODEL_TRN{subjcount};data4display];
            elseif ai==3, FORMODEL_TRN{subjcount}=[FORMODEL_TRN{subjcount};data4display];
            elseif ai==4, FORMODEL_TRN{subjcount}=[FORMODEL_TRN{subjcount};data4display];
            end
            
            % NOW Corrects only - after FORMODEL (should be 80)
            data4display=data4display(data4display(:,11)~=-3,:);
            
            % do RT slope by condi
            for typei=1:4
                if typei==1,     TEMP=data4display(data4display(:,3)==2,[5,9]); confidx=1;
                elseif typei==2, TEMP=data4display(data4display(:,3)==2,[5,9]); confidx=2;
                elseif typei==3, TEMP=data4display(data4display(:,3)==3,[5,9]); confidx=1;
                elseif typei==4, TEMP=data4display(data4display(:,3)==3,[5,9]); confidx=2;
                end
                MEGA_RTslope(subjcount,ai,typei)=corr(TEMP(TEMP(:,1)==confidx,2),[1:10]','type','Spearman'); clear TEMP confidx
            end
            
            CongRT=mean(data4display(data4display(:,5)==1,9));
            IncongRT=mean(data4display(data4display(:,5)==2,9));
            
            MEGA_TRN(subjcount,ai,:)=[subno,slowcount,errcount,errrt*1000,CongRT*1000,IncongRT*1000,err_p_incong];
            
            
            clear data4display Block slowcount errcount errrt CongRT IncongRT err_p_incong PEidx;
        end
        clear data_* randx_*;
        
        % TEST
        T1=load([num2str(subno),'_B1_Session',num2str(session),'_CC_test.mat']);
        T2=load([num2str(subno),'_B2_Session',num2str(session),'_CC_test.mat']);
        T3=load([num2str(subno),'_B3_Session',num2str(session),'_CC_test.mat']);
        T4=load([num2str(subno),'_B4_Session',num2str(session),'_CC_test.mat']);
        
        %   1=data_block
        %   2=count
        %   3=stimset
        %   4=response (1=resp, -1=noresp)
        %   5=resp key 68=left, 75=right
        %   6=RT
        %   7=acc (1,0,-1 for no resp)
        
        % % % % %         left_key=68;
        % % % % %         right_key=75;
        
        for ai=1:4
            if     ai==1, data4display=T1.data_test; Block='1'; div=48;
            elseif ai==2, data4display=T2.data_test; Block='2'; div=48;
            elseif ai==3, data4display=T3.data_test; Block='3'; div=48;
            elseif ai==4, data4display=T4.data_test; Block='4'; div=48;
            end
            
            temp=num2str(data4display(:,3));
            data4display(:,4)=str2num(temp(:,2));
            data4display(:,3)=str2num(temp(:,1));
            clear temp;
            
            % % % % % % % % % % % % % % %             % Fix accuracy due to prob in stim script
            % % % % % % % % % % % % % % %             if subno==101
            % % % % % % % % % % % % % % %                 for correcti=1:size(data4display,1)
            % % % % % % % % % % % % % % %                     if data4display(correcti,3)<data4display(correcti,4)
            % % % % % % % % % % % % % % %                         if data4display(correcti,5)==left_key,
            % % % % % % % % % % % % % % %                             data4display(correcti,7)=1;
            % % % % % % % % % % % % % % %                         else data4display(correcti,7)=0;
            % % % % % % % % % % % % % % %                         end
            % % % % % % % % % % % % % % %                     elseif data4display(correcti,4)<data4display(correcti,3)
            % % % % % % % % % % % % % % %                         if data4display(correcti,5)==right_key,
            % % % % % % % % % % % % % % %                             data4display(correcti,7)=1;
            % % % % % % % % % % % % % % %                         else data4display(correcti,7)=0;
            % % % % % % % % % % % % % % %                         end
            % % % % % % % % % % % % % % %                     end
            % % % % % % % % % % % % % % %                 end
            % % % % % % % % % % % % % % %             end
            
            
            if ai==1,     Block='1';
                FORMODEL_TEST{subjcount}=data4display;
            elseif ai==2, Block='2';
                FORMODEL_TEST{subjcount}=[FORMODEL_TEST{subjcount};data4display];
            elseif ai==3, Block='3';
                FORMODEL_TEST{subjcount}=[FORMODEL_TEST{subjcount};data4display];
            elseif ai==4, Block='4';
                FORMODEL_TEST{subjcount}=[FORMODEL_TEST{subjcount};data4display];
            end
            
            
            Au=data4display(data4display(:,3)==1,[4,6,7]);
            Bu=data4display(data4display(:,3)==2,[4,6,7]);
            Cu=data4display(data4display(:,3)==3,[4,6,7]);
            Du=data4display(data4display(:,3)==4,[4,6,7]);
            Ad=data4display(data4display(:,4)==1,[3,6,7]);
            Bd=data4display(data4display(:,4)==2,[3,6,7]);
            Cd=data4display(data4display(:,4)==3,[3,6,7]);
            Dd=data4display(data4display(:,4)==4,[3,6,7]);
            Aagg=[Au;Ad]; Bagg=[Bu;Bd]; Cagg=[Cu;Cd]; Dagg=[Du;Dd];
            clear Au Bu Cu Du Ad Bd Cd Dd;
            % no 99's
            Aagg=Aagg(Aagg(:,3)~=99,:);
            Bagg=Bagg(Bagg(:,3)~=99,:);
            Cagg=Cagg(Cagg(:,3)~=99,:);
            Dagg=Dagg(Dagg(:,3)~=99,:);
            % Acc
            AB=sum(Aagg(Aagg(:,1)==2,3)) ./ length(Aagg(Aagg(:,1)==2,3)) ;
            AC=sum(Aagg(Aagg(:,1)==3,3)) ./ length(Aagg(Aagg(:,1)==3,3)) ;
            AD=sum(Aagg(Aagg(:,1)==4,3)) ./ length(Aagg(Aagg(:,1)==4,3)) ;
            BC=sum(Bagg(Bagg(:,1)==3,3)) ./ length(Bagg(Bagg(:,1)==3,3)) ; % CC choices
            BD=sum(Bagg(Bagg(:,1)==4,3)) ./ length(Bagg(Bagg(:,1)==4,3)) ;
            CD=sum(Cagg(Cagg(:,1)==4,3)) ./ length(Cagg(Cagg(:,1)==4,3)) ;
            % RT
            AB_rt = mean(Aagg(Aagg(:,1)==2,2)) *1000 ;
            AC_rt = mean(Aagg(Aagg(:,1)==3,2)) *1000 ;
            AD_rt = mean(Aagg(Aagg(:,1)==4,2)) *1000 ;
            BC_rt = mean(Bagg(Bagg(:,1)==3,2)) *1000 ;
            BD_rt = mean(Bagg(Bagg(:,1)==4,2)) *1000 ;
            CD_rt = mean(Cagg(Cagg(:,1)==4,2)) *1000 ;
            
            % Aggregate
            MEGA_ACC(subjcount,ai,1)=AB; MEGA_ACC(subjcount,ai,2)=AC; MEGA_ACC(subjcount,ai,3)=AD;
            MEGA_ACC(subjcount,ai,4)=BC; MEGA_ACC(subjcount,ai,5)=BD; MEGA_ACC(subjcount,ai,6)=CD;
            MEGA_RT(subjcount,ai,1)=AB_rt; MEGA_RT(subjcount,ai,2)=AC_rt; MEGA_RT(subjcount,ai,3)=AD_rt;
            MEGA_RT(subjcount,ai,4)=BC_rt; MEGA_RT(subjcount,ai,5)=BD_rt; MEGA_RT(subjcount,ai,6)=CD_rt;
            % RT by Acc
            Aagg_c = Aagg(Aagg(:,3)==1,:);  Aagg_i = Aagg(Aagg(:,3)==0,:);
            Bagg_c = Bagg(Bagg(:,3)==1,:);  Bagg_i = Bagg(Bagg(:,3)==0,:);
            Cagg_c = Cagg(Cagg(:,3)==1,:);  Cagg_i = Cagg(Cagg(:,3)==0,:);
            AB_crt = mean(Aagg_c(Aagg_c(:,1)==2,2)) *1000 ;  AB_irt = mean(Aagg_i(Aagg_i(:,1)==2,2)) *1000 ;
            AC_crt = mean(Aagg_c(Aagg_c(:,1)==3,2)) *1000 ;  AC_irt = mean(Aagg_i(Aagg_i(:,1)==3,2)) *1000 ;
            AD_crt = mean(Aagg_c(Aagg_c(:,1)==4,2)) *1000 ;  AD_irt = mean(Aagg_i(Aagg_i(:,1)==4,2)) *1000 ;
            BC_crt = mean(Bagg_c(Bagg_c(:,1)==3,2)) *1000 ;  BC_irt = mean(Bagg_i(Bagg_i(:,1)==3,2)) *1000 ;
            BD_crt = mean(Bagg_c(Bagg_c(:,1)==4,2)) *1000 ;  BD_irt = mean(Bagg_i(Bagg_i(:,1)==4,2)) *1000 ;
            CD_crt = mean(Cagg_c(Cagg_c(:,1)==4,2)) *1000 ;  CD_irt = mean(Cagg_i(Cagg_i(:,1)==4,2)) *1000 ;
            % Aggregate
            MEGA_RT_c(subjcount,ai,1)=AB_crt; MEGA_RT_c(subjcount,ai,2)=AC_crt; MEGA_RT_c(subjcount,ai,3)=AD_crt;
            MEGA_RT_c(subjcount,ai,4)=BC_crt; MEGA_RT_c(subjcount,ai,5)=BD_crt; MEGA_RT_c(subjcount,ai,6)=CD_crt;
            MEGA_RT_i(subjcount,ai,1)=AB_irt; MEGA_RT_i(subjcount,ai,2)=AC_irt; MEGA_RT_i(subjcount,ai,3)=AD_irt;
            MEGA_RT_i(subjcount,ai,4)=BC_irt; MEGA_RT_i(subjcount,ai,5)=BD_irt; MEGA_RT_i(subjcount,ai,6)=CD_irt;

            % display accuracy
            % disp(['Block: ',Block, ' Total Acc: ',num2str((sum(data4display(data4display(:,8)~=99,8))/div)*100),'%']);
            disp(['Block: ',Block, ' Easy Acc: ',num2str(AD*100),'%']);
            disp(['Block: ',Block, ' Simple CC Acc: ',num2str(BC*100),'%']);
            disp(['Block: ',Block, ' Relative CC Acc: ',num2str(((AC-AB)+(BD-CD))*100),'%']);
            disp([' ']);
            
            clear *agg* AB AC AD BC BD CD data4display data4* *_rt *_crt *_irt;
            
        end
        
        
        PEslow_agg=0;
        if subno==803 && session==1  % Get rid of known bad blocks
            for bi=2:3  % 1 performance was OK, but at a different RT - - remember, 4 was a filler
                PEslow_agg=[PEslow_agg;PEslow{bi}];
            end
        else
            for bi=1:4
                PEslow_agg=[PEslow_agg;PEslow{bi}];
            end
        end
        MEGA_PE(subjcount,:)=mean(PEslow_agg(2:end));
        clear Data* PE*
        
        disp(['ERRORS (ERNs): ',num2str(sum(MEGA_TRN(subjcount,:,3)))]);
        disp([' ']);
        
    end
end
% Get rid of known bad blocks
ToManage=MEGA_ID(:,1)==803 .* MEGA_ID(:,2)==1;
MEGA_TRN(ToManage,[1,4],:)=NaN;
MEGA_RT(ToManage,[1,4],:)=NaN;
MEGA_RT_c(ToManage,[1,4],:)=NaN;
MEGA_RT_i(ToManage,[1,4],:)=NaN;
MEGA_ACC(ToManage,[1,4],:)=NaN;

save('CC_Behavior.mat','MEGA_ACC','MEGA_RT','MEGA_RT_c','MEGA_RT_i','MEGA_TRN','MEGA_PE','MEGA_ID','MEGA_RTslope');
save('CC_FORMODEL.mat','FORMODEL_TRN','FORMODEL_TEST');

%%
clear all; clc
datapath=('Y:\EEG_Data\PDDys\BEH\');
cd(datapath);

load('CC_Behavior.mat');
load('Y:\EEG_Data\PDDys\ONOFF.mat','ONOFF')
SUBJS=unique(MEGA_ID(:,1));

load('Y:\EEG_Data\PDDys\PD_Moderators.mat','Mods','Mods_Hdr')

[r,p]=corr(Mods(:,2),Mods(:,9),'rows','pairwise')

% % % $$$$$$$$$$$$$$$$$$$$ This forces everything to be by SESSION! $$$$$$$$$$$$$$$$$$$$
% % ONOFF(:,3)=repmat([1,0],1,28)';  %   ['ON'==S1,  'OFF'==S2]


if sum((MEGA_ID(:,1)-ONOFF(:,1))+(MEGA_ID(:,2)-ONOFF(:,2)))==0
    MEGA_ID=[MEGA_ID,ONOFF(:,3)];
else
    BOOM
end



for ai=1:size(MEGA_ID,1)
    for bi=1:length(SUBJS)
        if MEGA_ID(ai,1)==SUBJS(bi) && MEGA_ID(ai,3)==1   % ON
            ON.ID(bi,:)=SUBJS(bi);
            ON.PE(bi,:)=MEGA_PE(ai);
            
            ON.slows(bi,:)=squeeze(MEGA_TRN(ai,:,2));
            ON.errs(bi,:)=squeeze(MEGA_TRN(ai,:,3));
            ON.err_rt(bi,:)=squeeze(MEGA_TRN(ai,:,4));
            ON.cong_rt(bi,:)=squeeze(MEGA_TRN(ai,:,5));
            ON.incong_rt(bi,:)=squeeze(MEGA_TRN(ai,:,6));
            ON.err_p_incong(bi,:)=squeeze(MEGA_TRN(ai,:,7));
            ON.CongruEffect(bi,:)=ON.incong_rt(bi,:)-ON.cong_rt(bi,:);
            %
            ON.EASY(bi,:)=         MEGA_ACC(ai,:,3) ;
            ON.Direct_CC(bi,:) =   MEGA_ACC(ai,:,4) ;
            ON.Indirect_CC(bi,:) = (MEGA_ACC(ai,:,2)-MEGA_ACC(ai,:,1)) + (MEGA_ACC(ai,:,5)-MEGA_ACC(ai,:,6)) ;
            ON.EASY_RT(bi,:) =     MEGA_RT(ai,:,3) ;
            ON.Direct_CC_RT(bi,:) = MEGA_RT(ai,:,4) ;
            ON.Indirect_CC_RT(bi,:) = (MEGA_RT(ai,:,1)-MEGA_RT(ai,:,2)) + (MEGA_RT(ai,:,5)-MEGA_RT(ai,:,6)) ;
            %
            ON.EASY_cRT(bi,:) =        MEGA_RT_c(ai,:,3) ;
            ON.Direct_CC_cRT(bi,:) =   MEGA_RT_c(ai,:,4) ;
            ON.Indirect_CC_cRT(bi,:) = (MEGA_RT_c(ai,:,1)-MEGA_RT_c(ai,:,2)) + (MEGA_RT_c(ai,:,5)-MEGA_RT_c(ai,:,6)) ;
            ON.EASY_iRT(bi,:) =        MEGA_RT_i(ai,:,3) ;
            ON.Direct_CC_iRT(bi,:) =   MEGA_RT_i(ai,:,4) ;
            ON.Indirect_CC_iRT(bi,:) = (MEGA_RT_i(ai,:,1)-MEGA_RT_i(ai,:,2)) + (MEGA_RT_i(ai,:,5)-MEGA_RT_i(ai,:,6)) ;
            % 
            ON.RTslope(bi,:) = squeeze(mean(MEGA_RTslope(ai,:,:),2));
            
        elseif MEGA_ID(ai,1)==SUBJS(bi) && MEGA_ID(ai,3)==0   % OFF
            OFF.ID(bi,:)=SUBJS(bi);
            OFF.PE(bi,:)=MEGA_PE(ai);
            
            OFF.slows(bi,:)=squeeze(MEGA_TRN(ai,:,2));
            OFF.errs(bi,:)=squeeze(MEGA_TRN(ai,:,3));
            OFF.err_rt(bi,:)=squeeze(MEGA_TRN(ai,:,4));
            OFF.cong_rt(bi,:)=squeeze(MEGA_TRN(ai,:,5));
            OFF.incong_rt(bi,:)=squeeze(MEGA_TRN(ai,:,6));
            OFF.err_p_incong(bi,:)=squeeze(MEGA_TRN(ai,:,7));
            OFF.CongruEffect(bi,:)=OFF.incong_rt(bi,:)-OFF.cong_rt(bi,:);
            %
            OFF.EASY(bi,:)=         MEGA_ACC(ai,:,3) ;
            OFF.Direct_CC(bi,:) =   MEGA_ACC(ai,:,4) ;
            OFF.Indirect_CC(bi,:) = (MEGA_ACC(ai,:,2)-MEGA_ACC(ai,:,1)) + (MEGA_ACC(ai,:,5)-MEGA_ACC(ai,:,6)) ;
            OFF.EASY_RT(bi,:) =     MEGA_RT(ai,:,3) ;
            OFF.Direct_CC_RT(bi,:) = MEGA_RT(ai,:,4) ;
            OFF.Indirect_CC_RT(bi,:) = (MEGA_RT(ai,:,1)-MEGA_RT(ai,:,2)) + (MEGA_RT(ai,:,5)-MEGA_RT(ai,:,6)) ;
            %
            OFF.EASY_cRT(bi,:) =        MEGA_RT_c(ai,:,3) ;
            OFF.Direct_CC_cRT(bi,:) =   MEGA_RT_c(ai,:,4) ;
            OFF.Indirect_CC_cRT(bi,:) = (MEGA_RT_c(ai,:,1)-MEGA_RT_c(ai,:,2)) + (MEGA_RT_c(ai,:,5)-MEGA_RT_c(ai,:,6)) ;
            OFF.EASY_iRT(bi,:) =        MEGA_RT_i(ai,:,3) ;
            OFF.Direct_CC_iRT(bi,:) =   MEGA_RT_i(ai,:,4) ;
            OFF.Indirect_CC_iRT(bi,:) = (MEGA_RT_i(ai,:,1)-MEGA_RT_i(ai,:,2)) + (MEGA_RT_i(ai,:,5)-MEGA_RT_i(ai,:,6)) ;            
            % 
            OFF.RTslope(bi,:) = squeeze(mean(MEGA_RTslope(ai,:,:),2));
            
        end
    end
end

 
%%
CC_TRNHDR={'subno','slowcount','errcount','errrt','CongRT','IncongRT'};
BigN=size(ON.ID,1);
noise=rand(1,BigN)./100;

number=.66; % doesn't really matter
FILTER_ON=ones(BigN,4);   FILTER_ON(ON.EASY<number)=NaN;
FILTER_OFF=ones(BigN,4);   FILTER_OFF(OFF.EASY<number)=NaN;

% % % If some are bad, all are bad
% % FILTER_ON=repmat(FILTER_ON(:,1).*FILTER_ON(:,2).*FILTER_ON(:,3).*FILTER_ON(:,4),1,4);
% % FILTER_OFF=repmat(FILTER_OFF(:,1).*FILTER_OFF(:,2).*FILTER_OFF(:,3).*FILTER_OFF(:,4),1,4);

% % % Based on yrs dx
% % SOMESX=double(repmat((Mods(:,9)<nanmedian(Mods(:,9))),1,4));  % sum(Mods(:,9)==nanmedian(Mods(:,9)))
% % SOMESX(SOMESX==0)=NaN;
% % FILTER_ON=FILTER_ON.*SOMESX;
% % FILTER_OFF=FILTER_OFF.*SOMESX;


figure
subplot(2,3,1)
hold on
boxplot([sum(ON.errs,2),nansum(OFF.errs,2)])
set(gca,'xlim',[0 3],'xtick',[1:1:2],'xticklabel',{'ON','OFF'});
title('Error Ct');
subplot(2,3,2)
hold on
bar(1,nanmean(nanmean(ON.err_rt.*FILTER_ON,2)),.25,'w','Linewidth',2); errorbar(1,nanmean(nanmean(ON.err_rt.*FILTER_ON,2)),nanstd(nanmean(ON.err_rt.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(2,nanmean(nanmean(ON.cong_rt.*FILTER_ON,2)),.25,'w','Linewidth',2); errorbar(2,mean(nanmean(ON.cong_rt.*FILTER_ON,2)),nanstd(nanmean(ON.cong_rt.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(3,nanmean(nanmean(ON.incong_rt.*FILTER_ON,2)),.25,'w','Linewidth',2); errorbar(3,mean(nanmean(ON.incong_rt.*FILTER_ON,2)),nanstd(nanmean(ON.incong_rt.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(4,nanmean(ON.PE*1000),.25,'w','Linewidth',2); errorbar(4,nanmean(ON.PE*1000),nanstd(ON.PE*1000)./sqrt(BigN),'k:','Linewidth',2);
bar(1.25,nanmean(nanmean(OFF.err_rt.*FILTER_OFF,2)),.25,'r','Linewidth',2); errorbar(1.25,nanmean(nanmean(OFF.err_rt.*FILTER_OFF,2)),nanstd(nanmean(OFF.err_rt.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
bar(2.25,nanmean(nanmean(OFF.cong_rt.*FILTER_OFF,2)),.25,'r','Linewidth',2); errorbar(2.25,nanmean(nanmean(OFF.cong_rt.*FILTER_OFF,2)),nanstd(nanmean(OFF.cong_rt.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
bar(3.25,nanmean(nanmean(OFF.incong_rt.*FILTER_OFF,2)),.25,'r','Linewidth',2); errorbar(3.25,nanmean(nanmean(OFF.incong_rt.*FILTER_OFF,2)),nanstd(nanmean(OFF.incong_rt.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
bar(4.25,nanmean(OFF.PE*1000),.25,'r','Linewidth',2); errorbar(4.25,nanmean(OFF.PE*1000),nanstd(OFF.PE*1000)./sqrt(BigN),'k:','Linewidth',2);
title('RTs per condition');
set(gca,'ylim',[500 800],'xlim',[0 5],'xtick',[1:1:4],'xticklabel',{'Err','Cong','Incong','PEslow'});
subplot(2,3,3)
hold on
bar(1,nanmean(nanmean(ON.CongruEffect.*FILTER_ON,2)),'w','Linewidth',2); errorbar(1,nanmean(nanmean(ON.CongruEffect.*FILTER_ON,2)),nanstd(nanmean(ON.CongruEffect.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(2,nanmean(nanmean(OFF.CongruEffect.*FILTER_OFF,2)),'r','Linewidth',2); errorbar(2,nanmean(nanmean(OFF.CongruEffect.*FILTER_OFF,2)),nanstd(nanmean(OFF.CongruEffect.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
set(gca,'xlim',[0 3],'xtick',[1:1:2],'xticklabel',{'ON','OFF'});
title('Conflict');
subplot(2,3,4)
hold on
bar(1,nanmean(nanmean(ON.EASY.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Easy Acc
bar(2,nanmean(nanmean(ON.Direct_CC.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Direct CC
bar(3,.5+nanmean(nanmean(ON.Indirect_CC.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Indirect CC
errorbar(1,nanmean(nanmean(ON.EASY.*FILTER_ON,2),1),nanstd(nanmean(ON.EASY.*FILTER_ON,2),1) ./ sqrt(sum(~isnan(nanmean(ON.EASY.*FILTER_ON,2)))),'k:','Linewidth',2)
errorbar(2,nanmean(nanmean(ON.Direct_CC.*FILTER_ON,2),1),nanstd(nanmean(ON.Direct_CC.*FILTER_ON,2),1) ./ sqrt(sum(~isnan(nanmean(ON.Direct_CC.*FILTER_ON,2)))),'k:','Linewidth',2)
errorbar(3,.5+nanmean(nanmean(ON.Indirect_CC.*FILTER_ON,2),1),nanstd(nanmean(ON.Indirect_CC.*FILTER_ON,2),1) ./ sqrt(sum(~isnan(nanmean(ON.Indirect_CC.*FILTER_ON,2)))),'k:','Linewidth',2)
bar(1.25,nanmean(nanmean(OFF.EASY.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Easy Acc
bar(2.25,nanmean(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Direct CC
bar(3.25,.5+nanmean(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Indirect CC
errorbar(1.25,nanmean(nanmean(OFF.EASY.*FILTER_OFF,2),1),nanstd(nanmean(OFF.EASY.*FILTER_OFF,2),1) ./ sqrt(sum(~isnan(nanmean(OFF.EASY.*FILTER_OFF,2)))),'k:','Linewidth',2)
errorbar(2.25,nanmean(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1) ./ sqrt(sum(~isnan(nanmean(OFF.Direct_CC.*FILTER_OFF,2)))),'k:','Linewidth',2)
errorbar(3.25,.5+nanmean(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1) ./ sqrt(sum(~isnan(nanmean(OFF.Indirect_CC.*FILTER_OFF,2)))),'k:','Linewidth',2)
plot([0 4],[.5 .5],'b:','Linewidth',1);
plot([0 4],[0 0],'r:','Linewidth',1);
set(gca,'xlim',[0 4],'ylim',[-.1 1],'ytick',[-.1:.1:1],'xlim',[0 4],'xtick',[1:1:3],'xticklabel',{'EASY','SIMPLE','RELATIVE'});
ylabel('% Accuracy');
title('TOTAL Accuracy');
% 
[H,P,CI,STATS]=ttest(nanmean(ON.Direct_CC.*FILTER_ON,2),nanmean(OFF.Direct_CC.*FILTER_OFF,2))
text(.4,.98,['Simple t',num2str(STATS.df),'=',num2str(STATS.tstat),' p=',num2str(P)],'sc');
[H,P,CI,STATS]=ttest(nanmean(ON.Indirect_CC.*FILTER_ON,2),nanmean(OFF.Indirect_CC.*FILTER_OFF,2))
text(.4,.88,['Relative t',num2str(STATS.df),'=',num2str(STATS.tstat),' p=',num2str(P)],'sc');
[H,P,CI,STATS]=ttest(nanmean(ON.Direct_CC.*FILTER_ON,2),.5)
text(.5,.78,['ON t',num2str(STATS.df),'=',num2str(STATS.tstat),' p=',num2str(P)],'sc');
[H,P,CI,STATS]=ttest(nanmean(OFF.Direct_CC.*FILTER_OFF,2),.5)
text(.58,.68,['OFF t',num2str(STATS.df),'=',num2str(STATS.tstat),' p=',num2str(P)],'sc');
% For ANOVA
SPSS=[nanmean(ON.Direct_CC.*FILTER_ON,2),nanmean(OFF.Direct_CC.*FILTER_OFF,2),nanmean(ON.Indirect_CC.*FILTER_ON,2),nanmean(OFF.Indirect_CC.*FILTER_OFF,2)];
%
subplot(2,3,5)
hold on
bar(1,nanmean(nanmean(ON.EASY_RT.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Easy Acc
bar(2,nanmean(nanmean(ON.Direct_CC_RT.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Direct CC
errorbar(1,nanmean(nanmean(ON.EASY_RT.*FILTER_ON,2),1),nanstd(nanmean(ON.EASY_RT.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2,nanmean(nanmean(ON.Direct_CC_RT.*FILTER_ON,2),1),nanstd(nanmean(ON.Direct_CC_RT.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1.25,nanmean(nanmean(OFF.EASY_RT.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Easy Acc
bar(2.25,nanmean(nanmean(OFF.Direct_CC_RT.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Direct CC
errorbar(1.25,nanmean(nanmean(OFF.EASY_RT.*FILTER_OFF,2),1),nanstd(nanmean(OFF.EASY_RT.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2.25,nanmean(nanmean(OFF.Direct_CC_RT.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Direct_CC_RT.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
set(gca,'xlim',[0 3],'xtick',[1:1:2],'xticklabel',{'Easy','Simple'});
ylabel('RT');
title('TOTAL RTs');
subplot(2,3,6)
hold on
bar(1,nanmean(nanmean(ON.Indirect_CC_RT.*FILTER_ON,2),1),'w','Linewidth',2); % Indirect CC
errorbar(1,nanmean(nanmean(ON.Indirect_CC_RT.*FILTER_ON,2),1),nanstd(nanmean(ON.Indirect_CC_RT.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1.25,nanmean(nanmean(OFF.Indirect_CC_RT.*FILTER_OFF,2),1),'r','Linewidth',2); % Indirect CC
errorbar(1.25,nanmean(nanmean(OFF.Indirect_CC_RT.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Indirect_CC_RT.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
text(.1,.95,'(AB-AC)+(BD-BC)','sc');
set(gca,'xlim',[0 2],'xtick',[1:1:1],'xticklabel',{'Relative'});
ylabel('RT');
title('TOTAL RTs');


%%

ForSPSS=[nanmean(ON.Direct_CC.*FILTER_ON,2),nanmean(ON.Indirect_CC.*FILTER_ON,2),...
    nanmean(OFF.Direct_CC.*FILTER_OFF,2),nanmean(OFF.Indirect_CC.*FILTER_OFF,2),...
    nanmean(ON.Direct_CC.*FILTER_ON,2)-nanmean(OFF.Direct_CC.*FILTER_OFF,2),...
    nanmean(ON.Indirect_CC.*FILTER_ON,2)-nanmean(OFF.Indirect_CC.*FILTER_OFF,2)];

%%

figure
hold on
bar(1:4,mean(ON.RTslope),.25,'w','Linewidth',2);
bar(1.2:4.2,mean(OFF.RTslope),.25,'r','Linewidth',2);
errorbar(1:4,nanmean(ON.RTslope),std(ON.RTslope)./sqrt(BigN),'k.');
errorbar(1.2:4.2,nanmean(OFF.RTslope),std(OFF.RTslope)./sqrt(BigN),'k.');

%%

MOD_IDX=2;

A1=(nanmean(ON.Direct_CC.*FILTER_ON,2)) + (nanmean(ON.Indirect_CC.*FILTER_ON,2));
A2=(nanmean(OFF.Direct_CC.*FILTER_OFF,2)) + (nanmean(OFF.Indirect_CC.*FILTER_OFF,2));


A1=(nanmean(ON.Direct_CC.*FILTER_ON,2))  ;
A2=(nanmean(OFF.Direct_CC.*FILTER_OFF,2))  ;
A3=A1-A2;


figure; 
subplot(2,2,1); hold on
scatter( Mods(:,MOD_IDX) , A1 ,'k'); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , A1 ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['ON & ',Mods_Hdr{MOD_IDX}])
subplot(2,2,2); hold on
scatter( Mods(:,MOD_IDX) ,A2 ,'k' ); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , A2 ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['OFF & ',Mods_Hdr{MOD_IDX}])
subplot(2,2,3); hold on
scatter( Mods(:,MOD_IDX) , A3 ,'k'  ); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , A3 ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['ON-OFF & ',Mods_Hdr{MOD_IDX}])

%% MODS

MOD_IDX=9

CCd= (nanmean(OFF.Direct_CC.*FILTER_OFF,2)) - (nanmean(ON.Direct_CC.*FILTER_ON,2))  ;

figure; 
subplot(2,3,1); hold on
scatter( Mods(:,MOD_IDX) , (nanmean(OFF.Direct_CC.*FILTER_OFF,2)) ); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , (nanmean(OFF.Direct_CC.*FILTER_OFF,2)) ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['OFF & ',Mods_Hdr{MOD_IDX}])
subplot(2,3,2); hold on
scatter( Mods(:,MOD_IDX) ,(nanmean(ON.Direct_CC.*FILTER_ON,2)) ); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , (nanmean(ON.Direct_CC.*FILTER_ON,2)) ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['ON & ',Mods_Hdr{MOD_IDX}])
subplot(2,3,3); hold on
scatter( Mods(:,MOD_IDX) , CCd  ); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , CCd ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['OFF-ON & ',Mods_Hdr{MOD_IDX}])

CCd= (nanmean(OFF.Indirect_CC.*FILTER_OFF,2)) - (nanmean(ON.Indirect_CC.*FILTER_ON,2))  ;

subplot(2,3,4); hold on
scatter( Mods(:,MOD_IDX) , (nanmean(OFF.Indirect_CC.*FILTER_OFF,2)) ,'r'); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , (nanmean(OFF.Indirect_CC.*FILTER_OFF,2)) ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['OFF & ',Mods_Hdr{MOD_IDX}])
subplot(2,3,5); hold on
scatter( Mods(:,MOD_IDX) ,(nanmean(ON.Indirect_CC.*FILTER_ON,2)) ,'r'); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , (nanmean(ON.Indirect_CC.*FILTER_ON,2)) ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['ON & ',Mods_Hdr{MOD_IDX}])
subplot(2,3,6); hold on
scatter( Mods(:,MOD_IDX) , CCd  ,'r'); lsline
[rho,p]=corr( Mods(:,MOD_IDX) , CCd ,'type','Spearman','rows','complete' );
text(.4,.1,['r=',num2str(rho),' p=',num2str(p)],'sc')
title(['OFF-ON & ',Mods_Hdr{MOD_IDX}])







%%
CONFd=nanmean(OFF.CongruEffect,2) - nanmean(ON.CongruEffect,2);
RTd=((nanmean(OFF.cong_rt,2)+nanmean(OFF.incong_rt,2))./2) - ((nanmean(ON.cong_rt,2)+nanmean(ON.incong_rt,2))./2) ;
CCd= (nanmean(OFF.Direct_CC.*FILTER_ON,2)) - (nanmean(ON.Direct_CC.*FILTER_ON,2))  ;

figure; 
subplot(2,2,1); hold on
scatter( ((nanmean(ON.cong_rt,2)+nanmean(ON.incong_rt,2))./2) , nanmean(ON.Direct_CC.*FILTER_ON,2)  ); lsline
title('ON')
subplot(2,2,2); hold on
scatter( ((nanmean(OFF.cong_rt,2)+nanmean(OFF.incong_rt,2))./2) , nanmean(OFF.Direct_CC.*FILTER_OFF,2)  ); lsline
title('OFF')
subplot(2,2,3); hold on
scatter( ((nanmean(OFF.cong_rt,2)+nanmean(OFF.incong_rt,2))./2) , CCd  ); lsline
title('OFF RT & CCd')
subplot(2,2,4); hold on
scatter( RTd , CCd  ); lsline
title('RTd & CCd')

[rho,p]=corr( RTd , CCd ,'type','Spearman' )


figure; 
subplot(2,2,1); hold on
scatter( nanmean(ON.CongruEffect,2), nanmean(ON.Direct_CC.*FILTER_ON,2)  ); lsline
title('ON')
subplot(2,2,2); hold on
scatter( nanmean(OFF.CongruEffect,2) , nanmean(OFF.Direct_CC.*FILTER_OFF,2)  ); lsline
title('OFF')
subplot(2,2,3); hold on
scatter( nanmean(OFF.CongruEffect,2) , CCd  ); lsline
title('OFF CONF & CCd')
subplot(2,2,4); hold on
scatter( CONFd , CCd  ); lsline
title('CONFd & CCd')

[rho,p]=corr( nanmean(ON.CongruEffect,2), nanmean(ON.Direct_CC.*FILTER_ON,2) ,'type','Spearman' )



%%

load('BEH_CC_CTL.mat','CTL')

CC_TRNHDR={'subno','slowcount','errcount','errrt','CongRT','IncongRT'};
BigN=size(ON.ID,1);
noise=rand(1,BigN)./100;
BigN_ctl=size(CTL.ID,1);
noise_ctl=rand(1,BigN_ctl)./100;

FILTER_CTL=ones(BigN_ctl,4);   FILTER_CTL(CTL.EASY<number)=NaN;


figure
subplot(2,3,1)
hold on
boxplot([sum(ON.errs,2),nansum(OFF.errs,2),[sum(CTL.errs,2);repmat(NaN,size(sum(ON.errs,2),1)-size(sum(CTL.errs,2),1),1)]])
set(gca,'xlim',[0 4],'xtick',[1:1:3],'xticklabel',{'ON','OFF','CTL'});
title('Error Ct');
subplot(2,3,2)
hold on
bar(1-.25,nanmean(nanmean(ON.err_rt.*FILTER_ON,2)),.25,'w','Linewidth',2); errorbar(1-.25,nanmean(nanmean(ON.err_rt.*FILTER_ON,2)),nanstd(nanmean(ON.err_rt.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(2-.25,nanmean(nanmean(ON.cong_rt.*FILTER_ON,2)),.25,'w','Linewidth',2); errorbar(2-.25,nanmean(nanmean(ON.cong_rt.*FILTER_ON,2)),nanstd(nanmean(ON.cong_rt.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(3-.25,nanmean(nanmean(ON.incong_rt.*FILTER_ON,2)),.25,'w','Linewidth',2); errorbar(3-.25,nanmean(nanmean(ON.incong_rt.*FILTER_ON,2)),nanstd(nanmean(ON.incong_rt.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(4-.25,nanmean(ON.PE*1000),.25,'w','Linewidth',2); errorbar(4-.25,nanmean(ON.PE*1000),nanstd(ON.PE*1000)./sqrt(BigN),'k:','Linewidth',2);
bar(1,nanmean(nanmean(OFF.err_rt.*FILTER_OFF,2)),.25,'r','Linewidth',2); errorbar(1,nanmean(nanmean(OFF.err_rt.*FILTER_OFF,2)),nanstd(nanmean(OFF.err_rt.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
bar(2,nanmean(nanmean(OFF.cong_rt.*FILTER_OFF,2)),.25,'r','Linewidth',2); errorbar(2,nanmean(nanmean(OFF.cong_rt.*FILTER_OFF,2)),nanstd(nanmean(OFF.cong_rt.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
bar(3,nanmean(nanmean(OFF.incong_rt.*FILTER_OFF,2)),.25,'r','Linewidth',2); errorbar(3,nanmean(nanmean(OFF.incong_rt.*FILTER_OFF,2)),nanstd(nanmean(OFF.incong_rt.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
bar(4,nanmean(OFF.PE*1000),.25,'r','Linewidth',2); errorbar(4,nanmean(OFF.PE*1000),nanstd(OFF.PE*1000)./sqrt(BigN),'k:','Linewidth',2);
bar(1.25,nanmean(nanmean(CTL.err_rt.*FILTER_CTL,2)),.25,'g','Linewidth',2); errorbar(1.25,nanmean(nanmean(CTL.err_rt.*FILTER_CTL,2)),nanstd(nanmean(CTL.err_rt.*FILTER_CTL,2))./sqrt(BigN_ctl),'k:','Linewidth',2);
bar(2.25,nanmean(nanmean(CTL.cong_rt.*FILTER_CTL,2)),.25,'g','Linewidth',2); errorbar(2.25,nanmean(nanmean(CTL.cong_rt.*FILTER_CTL,2)),nanstd(nanmean(CTL.cong_rt.*FILTER_CTL,2))./sqrt(BigN_ctl),'k:','Linewidth',2);
bar(3.25,nanmean(nanmean(CTL.incong_rt.*FILTER_CTL,2)),.25,'g','Linewidth',2); errorbar(3.25,nanmean(nanmean(CTL.incong_rt.*FILTER_CTL,2)),nanstd(nanmean(CTL.incong_rt.*FILTER_CTL,2))./sqrt(BigN_ctl),'k:','Linewidth',2);
bar(4.25,nanmean(CTL.PE*1000),.25,'g','Linewidth',2); errorbar(4.25,nanmean(CTL.PE*1000),nanstd(CTL.PE*1000)./sqrt(BigN_ctl),'k:','Linewidth',2);
title('RTs per condition');
set(gca,'ylim',[400 800],'xlim',[0 5],'xtick',[1:1:4],'xticklabel',{'Err','Cong','Incong','PEslow'});
subplot(2,3,3)
hold on
bar(1,nanmean(nanmean(ON.CongruEffect.*FILTER_ON,2)),'w','Linewidth',2); errorbar(1,nanmean(nanmean(ON.CongruEffect.*FILTER_ON,2)),nanstd(nanmean(ON.CongruEffect.*FILTER_ON,2))./sqrt(BigN),'k:','Linewidth',2);
bar(2,nanmean(nanmean(OFF.CongruEffect.*FILTER_OFF,2)),'r','Linewidth',2); errorbar(2,nanmean(nanmean(OFF.CongruEffect.*FILTER_OFF,2)),nanstd(nanmean(OFF.CongruEffect.*FILTER_OFF,2))./sqrt(BigN),'k:','Linewidth',2);
bar(3,nanmean(nanmean(CTL.CongruEffect.*FILTER_CTL,2)),'g','Linewidth',2); errorbar(3,nanmean(nanmean(CTL.CongruEffect.*FILTER_CTL,2)),nanstd(nanmean(CTL.CongruEffect.*FILTER_CTL,2))./sqrt(BigN_ctl),'k:','Linewidth',2);
set(gca,'xlim',[0 4],'xtick',[1:1:3],'xticklabel',{'ON','OFF','CTL'});
title('Conflict');
subplot(2,3,4)
hold on
bar(1-.25,nanmean(nanmean(ON.EASY.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Easy Acc
bar(2-.25,nanmean(nanmean(ON.Direct_CC.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Direct CC
bar(3-.25,nanmean(nanmean(ON.Indirect_CC.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Indirect CC
errorbar(1-.25,nanmean(nanmean(ON.EASY.*FILTER_ON,2),1),nanstd(nanmean(ON.EASY.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2-.25,nanmean(nanmean(ON.Direct_CC.*FILTER_ON,2),1),nanstd(nanmean(ON.Direct_CC.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(3-.25,nanmean(nanmean(ON.Indirect_CC.*FILTER_ON,2),1),nanstd(nanmean(ON.Indirect_CC.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1,nanmean(nanmean(OFF.EASY.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Easy Acc
bar(2,nanmean(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Direct CC
bar(3,nanmean(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Indirect CC
errorbar(1,nanmean(nanmean(OFF.EASY.*FILTER_OFF,2),1),nanstd(nanmean(OFF.EASY.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2,nanmean(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(3,nanmean(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1.25,nanmean(nanmean(CTL.EASY.*FILTER_CTL,2),1),.25,'g','Linewidth',2); % Easy Acc
bar(2.25,nanmean(nanmean(CTL.Direct_CC.*FILTER_CTL,2),1),.25,'g','Linewidth',2); % Direct CC
bar(3.25,nanmean(nanmean(CTL.Indirect_CC.*FILTER_CTL,2),1),.25,'g','Linewidth',2); % Indirect CC
errorbar(1.25,nanmean(nanmean(CTL.EASY.*FILTER_CTL,2),1),nanstd(nanmean(CTL.EASY.*FILTER_CTL,2),1) ./ sqrt(BigN_ctl),'k:','Linewidth',2)
errorbar(2.25,nanmean(nanmean(CTL.Direct_CC.*FILTER_CTL,2),1),nanstd(nanmean(CTL.Direct_CC.*FILTER_CTL,2),1) ./ sqrt(BigN_ctl),'k:','Linewidth',2)
errorbar(3.25,nanmean(nanmean(CTL.Indirect_CC.*FILTER_CTL,2),1),nanstd(nanmean(CTL.Indirect_CC.*FILTER_CTL,2),1) ./ sqrt(BigN_ctl),'k:','Linewidth',2)
plot([0 1],[.5 .5],'b','Linewidth',5);
plot([0 1],[0 0],'r','Linewidth',5);
set(gca,'xlim',[0 4],'ylim',[-.2 1],'ytick',[-.2:.1:1],'xlim',[0 4],'xtick',[1:1:3],'xticklabel',{'EASY','SIMPLE','RELATIVE'});
ylabel('% Accuracy');
title('TOTAL Accuracy');
%
subplot(2,3,5)
hold on
bar(1-.25,nanmean(nanmean(ON.EASY_RT.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Easy Acc
bar(2-.25,nanmean(nanmean(ON.Direct_CC_RT.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Direct CC
errorbar(1-.25,nanmean(nanmean(ON.EASY_RT.*FILTER_ON,2),1),nanstd(nanmean(ON.EASY_RT.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2-.25,nanmean(nanmean(ON.Direct_CC_RT.*FILTER_ON,2),1),nanstd(nanmean(ON.Direct_CC_RT.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1,nanmean(nanmean(OFF.EASY_RT.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Easy Acc
bar(2,nanmean(nanmean(OFF.Direct_CC_RT.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Direct CC
errorbar(1,nanmean(nanmean(OFF.EASY_RT.*FILTER_OFF,2),1),nanstd(nanmean(OFF.EASY_RT.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
errorbar(2,nanmean(nanmean(OFF.Direct_CC_RT.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Direct_CC_RT.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1.25,nanmean(nanmean(CTL.EASY_RT.*FILTER_CTL,2),1),.25,'g','Linewidth',2); % Easy Acc
bar(2.25,nanmean(nanmean(CTL.Direct_CC_RT.*FILTER_CTL,2),1),.25,'g','Linewidth',2); % Direct CC
errorbar(1.25,nanmean(nanmean(CTL.EASY_RT.*FILTER_CTL,2),1),nanstd(nanmean(CTL.EASY_RT.*FILTER_CTL,2),1) ./ sqrt(BigN_ctl),'k:','Linewidth',2)
errorbar(2.25,nanmean(nanmean(CTL.Direct_CC_RT.*FILTER_CTL,2),1),nanstd(nanmean(CTL.Direct_CC_RT.*FILTER_CTL,2),1) ./ sqrt(BigN_ctl),'k:','Linewidth',2)
set(gca,'xlim',[0 3],'xtick',[1:1:2],'xticklabel',{'Easy','Simple'});
ylabel('RT');
title('TOTAL RTs');
subplot(2,3,6)
hold on
bar(1-.25,nanmean(nanmean(ON.Indirect_CC_RT.*FILTER_ON,2),1),'w','Linewidth',2); % Indirect CC
errorbar(1-.25,nanmean(nanmean(ON.Indirect_CC_RT.*FILTER_ON,2),1),nanstd(nanmean(ON.Indirect_CC_RT.*FILTER_ON,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1,nanmean(nanmean(OFF.Indirect_CC_RT.*FILTER_OFF,2),1),'r','Linewidth',2); % Indirect CC
errorbar(1,nanmean(nanmean(OFF.Indirect_CC_RT.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Indirect_CC_RT.*FILTER_OFF,2),1) ./ sqrt(BigN),'k:','Linewidth',2)
bar(1.25,nanmean(nanmean(CTL.Indirect_CC_RT.*FILTER_CTL,2),1),'g','Linewidth',2); % Indirect CC
errorbar(1.25,nanmean(nanmean(CTL.Indirect_CC_RT.*FILTER_CTL,2),1),nanstd(nanmean(CTL.Indirect_CC_RT.*FILTER_CTL,2),1) ./ sqrt(BigN_ctl),'k:','Linewidth',2)
text(.1,.95,'(AB-AC)+(BD-BC)','sc');
set(gca,'xlim',[0 2],'xtick',[1:1:1],'xticklabel',{'Relative'});
ylabel('RT');
title('TOTAL RTs');


%%

figure
subplot(2,1,1)
hold on
bar(1,nanmean(nanmean(ON.EASY.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Easy Acc
bar(2,nanmean(nanmean(ON.Direct_CC.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Direct CC
bar(3,.5+nanmean(nanmean(ON.Indirect_CC.*FILTER_ON,2),1),.25,'w','Linewidth',2); % Indirect CC
errorbar(1,nanmean(nanmean(ON.EASY.*FILTER_ON,2),1),nanstd(nanmean(ON.EASY.*FILTER_ON,2),1) ./ sqrt(sum(~isnan(nanmean(ON.EASY.*FILTER_ON,2)))),'k:','Linewidth',2)
errorbar(2,nanmean(nanmean(ON.Direct_CC.*FILTER_ON,2),1),nanstd(nanmean(ON.Direct_CC.*FILTER_ON,2),1) ./ sqrt(sum(~isnan(nanmean(ON.Direct_CC.*FILTER_ON,2)))),'k:','Linewidth',2)
errorbar(3,.5+nanmean(nanmean(ON.Indirect_CC.*FILTER_ON,2),1),nanstd(nanmean(ON.Indirect_CC.*FILTER_ON,2),1) ./ sqrt(sum(~isnan(nanmean(ON.Indirect_CC.*FILTER_ON,2)))),'k:','Linewidth',2)
bar(1.25,nanmean(nanmean(OFF.EASY.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Easy Acc
bar(2.25,nanmean(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Direct CC
bar(3.25,.5+nanmean(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1),.25,'r','Linewidth',2); % Indirect CC
errorbar(1.25,nanmean(nanmean(OFF.EASY.*FILTER_OFF,2),1),nanstd(nanmean(OFF.EASY.*FILTER_OFF,2),1) ./ sqrt(sum(~isnan(nanmean(OFF.EASY.*FILTER_OFF,2)))),'k:','Linewidth',2)
errorbar(2.25,nanmean(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Direct_CC.*FILTER_OFF,2),1) ./ sqrt(sum(~isnan(nanmean(OFF.Direct_CC.*FILTER_OFF,2)))),'k:','Linewidth',2)
errorbar(3.25,.5+nanmean(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1),nanstd(nanmean(OFF.Indirect_CC.*FILTER_OFF,2),1) ./ sqrt(sum(~isnan(nanmean(OFF.Indirect_CC.*FILTER_OFF,2)))),'k:','Linewidth',2)
plot([0 4],[.5 .5],'b:','Linewidth',1);
plot([0 4],[0 0],'r:','Linewidth',1);

plot(1,nanmean(ON.EASY.*FILTER_ON,2),'bd'); % Easy Acc
plot(2,nanmean(ON.Direct_CC.*FILTER_ON,2),'bd'); % Direct CC
plot(3,.5+nanmean(ON.Indirect_CC.*FILTER_ON,2),'bd'); % Indirect CC

plot(1.25,nanmean(OFF.EASY.*FILTER_OFF,2),'kd'); % Easy Acc
plot(2.25,nanmean(OFF.Direct_CC.*FILTER_OFF,2),'kd'); % Direct CC
plot(3.25,.5+nanmean(OFF.Indirect_CC.*FILTER_OFF,2),'kd'); % Indirect CC

plot([1 1.25],[nanmean(ON.EASY.*FILTER_ON,2) nanmean(OFF.EASY.*FILTER_OFF,2)],'b-'); % Easy Acc
plot([2 2.25],[nanmean(ON.Direct_CC.*FILTER_ON,2) nanmean(OFF.Direct_CC.*FILTER_OFF,2)],'b-'); % Direct CC
plot([3 3.25],[.5+nanmean(ON.Indirect_CC.*FILTER_ON,2) .5+nanmean(OFF.Indirect_CC.*FILTER_OFF,2)],'b-'); % Indirect CC

set(gca,'xlim',[0 4],'ylim',[-.1 1],'ytick',[-.1:.1:1],'xlim',[0 4],'xtick',[1:1:3],'xticklabel',{'EASY','SIMPLE','RELATIVE'});
ylabel('% Accuracy');
title('TOTAL Accuracy by Subj');

jit=(rand(1,28)./5)-.05;
subplot(2,1,2)
hold on
plot(1+jit,nanmean(ON.EASY.*FILTER_ON,2)-nanmean(OFF.EASY.*FILTER_OFF,2),'md'); % Easy Acc
plot(2+jit,nanmean(ON.Direct_CC.*FILTER_ON,2)-nanmean(OFF.Direct_CC.*FILTER_OFF,2),'md'); % Direct CC
plot(3+jit,nanmean(ON.Indirect_CC.*FILTER_ON,2)-nanmean(OFF.Indirect_CC.*FILTER_OFF,2),'md'); % Indirect CC
plot([0 4],[0 0],'r:','Linewidth',1);
set(gca,'xlim',[0 4],'ylim',[-1 1],'ytick',[-1:.25:1],'xlim',[0 4],'xtick',[1:1:3],'xticklabel',{'EASY','SIMPLE','RELATIVE'});
title('ON minus OFF')


