package com.janrain.yadis;

import java.util.List;
import java.util.Set;

import org.w3c.dom.Node;

public interface ServiceParser
{
    public abstract Set getSupportedTypes();

    public abstract List parseService(Node n);
}
